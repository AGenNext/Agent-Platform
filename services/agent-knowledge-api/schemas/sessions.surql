-- Schema: sessions
-- Multi-turn agent conversation sessions.
-- A session groups messages between a user/agent pair under a single thread.
-- LIVE SELECT delivers new messages in real time — no polling needed.

DEFINE TABLE session SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE session TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE session TYPE string DEFAULT 'Conversation';

-- Identity
DEFINE FIELD session_id    ON TABLE session TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE session TYPE string ASSERT $value != NONE;
DEFINE FIELD user_id       ON TABLE session TYPE option<string>;
DEFINE FIELD agent_id      ON TABLE session TYPE string ASSERT $value != NONE;
DEFINE FIELD objective_id  ON TABLE session TYPE option<record<objective>>;

-- Session context
DEFINE FIELD title         ON TABLE session TYPE option<string>;
DEFINE FIELD channel       ON TABLE session TYPE string DEFAULT 'api'
    ASSERT $value IN ['api', 'dashboard', 'slack', 'teams', 'webhook', 'sdk', 'a2a'];
DEFINE FIELD status        ON TABLE session TYPE string DEFAULT 'active'
    ASSERT $value IN ['active', 'idle', 'completed', 'archived', 'error'];

-- Metadata
DEFINE FIELD message_count ON TABLE session TYPE int DEFAULT 0;
DEFINE FIELD token_count   ON TABLE session TYPE int DEFAULT 0;
DEFINE FIELD model_id      ON TABLE session TYPE option<string>;
DEFINE FIELD metadata      ON TABLE session TYPE object DEFAULT {};

DEFINE FIELD started_at    ON TABLE session TYPE datetime DEFAULT time::now();
DEFINE FIELD last_active   ON TABLE session TYPE datetime DEFAULT time::now();
DEFINE FIELD ended_at      ON TABLE session TYPE option<datetime>;

DEFINE INDEX idx_session_id     ON TABLE session COLUMNS session_id UNIQUE;
DEFINE INDEX idx_session_agent  ON TABLE session COLUMNS agent_id;
DEFINE INDEX idx_session_user   ON TABLE session COLUMNS user_id;
DEFINE INDEX idx_session_tenant ON TABLE session COLUMNS tenant_id;
DEFINE INDEX idx_session_status ON TABLE session COLUMNS status;

-- ─── Message ─────────────────────────────────────────────────────────────────

DEFINE TABLE message SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE message TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE message TYPE string DEFAULT 'Message';

DEFINE FIELD session_id    ON TABLE message TYPE record<session> ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE message TYPE string ASSERT $value != NONE;

-- Conversational role
DEFINE FIELD role          ON TABLE message TYPE string DEFAULT 'user'
    ASSERT $value IN ['user', 'assistant', 'system', 'tool', 'function'];

DEFINE FIELD content       ON TABLE message TYPE string ASSERT $value != NONE;
DEFINE FIELD content_type  ON TABLE message TYPE string DEFAULT 'text'
    ASSERT $value IN ['text', 'markdown', 'json', 'tool_call', 'tool_result', 'image', 'file'];

-- Tool use (role = 'tool' or 'function')
DEFINE FIELD tool_name     ON TABLE message TYPE option<string>;
DEFINE FIELD tool_call_id  ON TABLE message TYPE option<string>;
DEFINE FIELD tool_input    ON TABLE message TYPE option<object>;
DEFINE FIELD tool_output   ON TABLE message TYPE option<string>;

-- Token accounting
DEFINE FIELD tokens_in     ON TABLE message TYPE int DEFAULT 0;
DEFINE FIELD tokens_out    ON TABLE message TYPE int DEFAULT 0;
DEFINE FIELD cost_usd      ON TABLE message TYPE float DEFAULT 0.0;
DEFINE FIELD model_id      ON TABLE message TYPE option<string>;
DEFINE FIELD latency_ms    ON TABLE message TYPE option<int>;

-- Feedback / rating from user
DEFINE FIELD rating        ON TABLE message TYPE option<int>;  -- 1-5
DEFINE FIELD flagged       ON TABLE message TYPE bool DEFAULT false;

DEFINE FIELD metadata      ON TABLE message TYPE object DEFAULT {};
DEFINE FIELD created_at    ON TABLE message TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_msg_session ON TABLE message COLUMNS session_id;
DEFINE INDEX idx_msg_tenant  ON TABLE message COLUMNS tenant_id;
DEFINE INDEX idx_msg_role    ON TABLE message COLUMNS role;
DEFINE INDEX idx_msg_created ON TABLE message COLUMNS created_at;

-- FTS on message content
DEFINE INDEX idx_msg_fts
    ON TABLE message
    FIELDS content
    SEARCH ANALYZER analyzer_en BM25(1.2, 0.75)
    HIGHLIGHTS;

-- ─── Auto-update session stats on each new message ───────────────────────────

DEFINE EVENT session_message_added ON TABLE message
    WHEN $event = 'CREATE'
    THEN (
        UPDATE $after.session_id SET
            message_count += 1,
            token_count   += ($after.tokens_in + $after.tokens_out),
            last_active    = time::now()
    );

-- ─── Close session when objective completes ──────────────────────────────────

DEFINE EVENT session_objective_done ON TABLE objective
    WHEN $event = 'UPDATE' AND $after.status = 'completed'
    THEN (
        UPDATE session SET
            status   = 'completed',
            ended_at = time::now()
        WHERE objective_id = $after.id AND status = 'active'
    );

-- ─── Live query pattern ───────────────────────────────────────────────────────
-- LIVE SELECT * FROM message
-- WHERE session_id = $session_id
-- ORDER BY created_at ASC;
