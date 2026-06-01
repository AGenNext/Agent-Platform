USE NS agennext DB database_as_agents;

CREATE skill:triage SET
  name = "Ticket Triage",
  description = "Classify, prioritize, and route support tickets";

CREATE skill:security_review SET
  name = "Security Review",
  description = "Review high-risk tickets and recommend escalation";

CREATE agent:support_triage SET
  name = "Support Triage Agent",
  role = "ticket_triage",
  status = "active",
  capabilities = ["classify_ticket", "assign_priority", "route_ticket"],
  trust_score = 0.92;

CREATE agent:security_reviewer SET
  name = "Security Reviewer Agent",
  role = "security_review",
  status = "active",
  capabilities = ["risk_assessment", "policy_check", "escalation"],
  trust_score = 0.88;

RELATE agent:support_triage->can_perform->skill:triage;
RELATE agent:security_reviewer->can_perform->skill:security_review;

CREATE ticket SET
  title = "Customer cannot login",
  description = "Customer reports login failure after password reset.",
  priority = "medium";

CREATE ticket SET
  title = "Possible payment data breach",
  description = "Customer says payment details may have leaked after checkout.",
  priority = "critical";
