DEFINE TABLE applications SCHEMAFULL;
DEFINE FIELD tenant_id ON applications TYPE option<record<tenants>>;
DEFINE FIELD key ON applications TYPE string;
DEFINE FIELD name ON applications TYPE string;
DEFINE FIELD description ON applications TYPE string;
DEFINE FIELD application_kind ON applications TYPE string DEFAULT 'agentic_application';
DEFINE FIELD owner_id ON applications TYPE string;
DEFINE FIELD status ON applications TYPE string DEFAULT 'active';
DEFINE FIELD default_environment_config_id ON applications TYPE option<record<environment_configurations>>;
DEFINE FIELD default_tool_config_id ON applications TYPE option<record<tool_configurations>>;
DEFINE FIELD jsonld_context ON applications TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON applications TYPE array<string> DEFAULT ['schema:SoftwareApplication', 'agx:Application'];
DEFINE FIELD created_at ON applications TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON applications TYPE datetime DEFAULT time::now();
DEFINE INDEX applications_key_unique ON applications FIELDS tenant_id, key UNIQUE;

DEFINE TABLE projects SCHEMAFULL;
DEFINE FIELD tenant_id ON projects TYPE option<record<tenants>>;
DEFINE FIELD application_id ON projects TYPE option<record<applications>>;
DEFINE FIELD key ON projects TYPE string;
DEFINE FIELD name ON projects TYPE string;
DEFINE FIELD description ON projects TYPE string;
DEFINE FIELD owner_id ON projects TYPE string;
DEFINE FIELD status ON projects TYPE string DEFAULT 'active';
DEFINE FIELD priority ON projects TYPE string DEFAULT 'medium';
DEFINE FIELD start_at ON projects TYPE option<datetime>;
DEFINE FIELD target_end_at ON projects TYPE option<datetime>;
DEFINE FIELD default_environment_config_id ON projects TYPE option<record<environment_configurations>>;
DEFINE FIELD default_tool_config_id ON projects TYPE option<record<tool_configurations>>;
DEFINE FIELD default_collaboration_space_id ON projects TYPE option<record<collaboration_spaces>>;
DEFINE FIELD jsonld_context ON projects TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON projects TYPE array<string> DEFAULT ['schema:Project', 'agx:Project'];
DEFINE FIELD created_at ON projects TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON projects TYPE datetime DEFAULT time::now();
DEFINE INDEX projects_key_unique ON projects FIELDS tenant_id, key UNIQUE;

DEFINE TABLE milestones SCHEMAFULL;
DEFINE FIELD tenant_id ON milestones TYPE option<record<tenants>>;
DEFINE FIELD project_id ON milestones TYPE record<projects>;
DEFINE FIELD key ON milestones TYPE string;
DEFINE FIELD name ON milestones TYPE string;
DEFINE FIELD description ON milestones TYPE string;
DEFINE FIELD status ON milestones TYPE string DEFAULT 'planned';
DEFINE FIELD target_at ON milestones TYPE option<datetime>;
DEFINE FIELD completion_criteria ON milestones TYPE array<object> DEFAULT [];
DEFINE FIELD default_environment_config_id ON milestones TYPE option<record<environment_configurations>>;
DEFINE FIELD default_tool_config_id ON milestones TYPE option<record<tool_configurations>>;
DEFINE FIELD default_collaboration_space_id ON milestones TYPE option<record<collaboration_spaces>>;
DEFINE FIELD jsonld_context ON milestones TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON milestones TYPE array<string> DEFAULT ['schema:Event', 'agx:Milestone'];
DEFINE FIELD created_at ON milestones TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON milestones TYPE datetime DEFAULT time::now();
DEFINE INDEX milestones_key_unique ON milestones FIELDS project_id, key UNIQUE;

DEFINE TABLE tasks SCHEMAFULL;
DEFINE FIELD tenant_id ON tasks TYPE option<record<tenants>>;
DEFINE FIELD project_id ON tasks TYPE option<record<projects>>;
DEFINE FIELD milestone_id ON tasks TYPE option<record<milestones>>;
DEFINE FIELD application_id ON tasks TYPE option<record<applications>>;
DEFINE FIELD key ON tasks TYPE string;
DEFINE FIELD title ON tasks TYPE string;
DEFINE FIELD description ON tasks TYPE string;
DEFINE FIELD status ON tasks TYPE string DEFAULT 'todo';
DEFINE FIELD priority ON tasks TYPE string DEFAULT 'medium';
DEFINE FIELD assignee_ids ON tasks TYPE array<string> DEFAULT [];
DEFINE FIELD required_outputs ON tasks TYPE array<object> DEFAULT [];
DEFINE FIELD acceptance_criteria ON tasks TYPE array<object> DEFAULT [];
DEFINE FIELD default_environment_config_id ON tasks TYPE option<record<environment_configurations>>;
DEFINE FIELD default_tool_config_id ON tasks TYPE option<record<tool_configurations>>;
DEFINE FIELD default_collaboration_space_id ON tasks TYPE option<record<collaboration_spaces>>;
DEFINE FIELD jsonld_context ON tasks TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON tasks TYPE array<string> DEFAULT ['schema:Action', 'agx:Task'];
DEFINE FIELD created_at ON tasks TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON tasks TYPE datetime DEFAULT time::now();
DEFINE INDEX tasks_key_unique ON tasks FIELDS tenant_id, key UNIQUE;

DEFINE TABLE environment_configurations SCHEMAFULL;
DEFINE FIELD tenant_id ON environment_configurations TYPE option<record<tenants>>;
DEFINE FIELD key ON environment_configurations TYPE string;
DEFINE FIELD name ON environment_configurations TYPE string;
DEFINE FIELD scope_kind ON environment_configurations TYPE string;
DEFINE FIELD scope_ref ON environment_configurations TYPE option<record>;
DEFINE FIELD runtime_environment ON environment_configurations TYPE object DEFAULT {};
DEFINE FIELD secrets_policy ON environment_configurations TYPE object DEFAULT {};
DEFINE FIELD network_policy ON environment_configurations TYPE object DEFAULT {};
DEFINE FIELD data_access_policy ON environment_configurations TYPE object DEFAULT {};
DEFINE FIELD observability_policy ON environment_configurations TYPE object DEFAULT {};
DEFINE FIELD enabled ON environment_configurations TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON environment_configurations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON environment_configurations TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:EnvironmentConfiguration'];
DEFINE FIELD created_at ON environment_configurations TYPE datetime DEFAULT time::now();
DEFINE INDEX environment_configurations_key_unique ON environment_configurations FIELDS tenant_id, key UNIQUE;

DEFINE TABLE tool_configurations SCHEMAFULL;
DEFINE FIELD tenant_id ON tool_configurations TYPE option<record<tenants>>;
DEFINE FIELD key ON tool_configurations TYPE string;
DEFINE FIELD name ON tool_configurations TYPE string;
DEFINE FIELD scope_kind ON tool_configurations TYPE string;
DEFINE FIELD scope_ref ON tool_configurations TYPE option<record>;
DEFINE FIELD allowed_tools ON tool_configurations TYPE array<string> DEFAULT [];
DEFINE FIELD denied_tools ON tool_configurations TYPE array<string> DEFAULT [];
DEFINE FIELD tool_settings ON tool_configurations TYPE object DEFAULT {};
DEFINE FIELD tool_approval_policy ON tool_configurations TYPE object DEFAULT { require_human_approval: false };
DEFINE FIELD max_tool_calls ON tool_configurations TYPE int DEFAULT 32;
DEFINE FIELD enabled ON tool_configurations TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON tool_configurations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON tool_configurations TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:ToolConfiguration'];
DEFINE FIELD created_at ON tool_configurations TYPE datetime DEFAULT time::now();
DEFINE INDEX tool_configurations_key_unique ON tool_configurations FIELDS tenant_id, key UNIQUE;

DEFINE TABLE collaboration_spaces SCHEMAFULL;
DEFINE FIELD tenant_id ON collaboration_spaces TYPE option<record<tenants>>;
DEFINE FIELD key ON collaboration_spaces TYPE string;
DEFINE FIELD name ON collaboration_spaces TYPE string;
DEFINE FIELD scope_kind ON collaboration_spaces TYPE string;
DEFINE FIELD scope_ref ON collaboration_spaces TYPE option<record>;
DEFINE FIELD human_participant_ids ON collaboration_spaces TYPE array<string> DEFAULT [];
DEFINE FIELD agent_participant_ids ON collaboration_spaces TYPE array<string> DEFAULT [];
DEFINE FIELD application_ids ON collaboration_spaces TYPE array<record<applications>> DEFAULT [];
DEFINE FIELD collaboration_policy ON collaboration_spaces TYPE object DEFAULT { human_approval_required_for: ['high_risk_actions'], agent_autonomy_level: 'bounded' };
DEFINE FIELD shared_context ON collaboration_spaces TYPE object DEFAULT {};
DEFINE FIELD status ON collaboration_spaces TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON collaboration_spaces TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON collaboration_spaces TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:CollaborationSpace'];
DEFINE FIELD created_at ON collaboration_spaces TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON collaboration_spaces TYPE datetime DEFAULT time::now();
DEFINE INDEX collaboration_spaces_key_unique ON collaboration_spaces FIELDS tenant_id, key UNIQUE;

DEFINE TABLE effective_execution_configurations SCHEMAFULL;
DEFINE FIELD tenant_id ON effective_execution_configurations TYPE option<record<tenants>>;
DEFINE FIELD application_id ON effective_execution_configurations TYPE option<record<applications>>;
DEFINE FIELD project_id ON effective_execution_configurations TYPE option<record<projects>>;
DEFINE FIELD milestone_id ON effective_execution_configurations TYPE option<record<milestones>>;
DEFINE FIELD task_id ON effective_execution_configurations TYPE option<record<tasks>>;
DEFINE FIELD environment_config_id ON effective_execution_configurations TYPE option<record<environment_configurations>>;
DEFINE FIELD tool_config_id ON effective_execution_configurations TYPE option<record<tool_configurations>>;
DEFINE FIELD collaboration_space_id ON effective_execution_configurations TYPE option<record<collaboration_spaces>>;
DEFINE FIELD effective_environment ON effective_execution_configurations TYPE object DEFAULT {};
DEFINE FIELD effective_tools ON effective_execution_configurations TYPE object DEFAULT {};
DEFINE FIELD effective_collaboration ON effective_execution_configurations TYPE object DEFAULT {};
DEFINE FIELD resolution_order ON effective_execution_configurations TYPE array<string> DEFAULT [];
DEFINE FIELD decision_log_id ON effective_execution_configurations TYPE option<record<decision_context_logs>>;
DEFINE FIELD jsonld_context ON effective_execution_configurations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON effective_execution_configurations TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:EffectiveExecutionConfiguration'];
DEFINE FIELD created_at ON effective_execution_configurations TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::create_application($tenant_id, $key, $name, $description, $owner_id) {
  LET $existing = SELECT * FROM applications WHERE tenant_id = $tenant_id AND key = $key LIMIT 1;
  IF count($existing) > 0 THEN { RETURN $existing[0]; };
  RETURN CREATE applications CONTENT { tenant_id: $tenant_id, key: $key, name: $name, description: $description, owner_id: $owner_id, status: 'active', created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::create_project($tenant_id, $application_id, $key, $name, $description, $owner_id, $priority, $start_at, $target_end_at) {
  RETURN CREATE projects CONTENT { tenant_id: $tenant_id, application_id: $application_id, key: $key, name: $name, description: $description, owner_id: $owner_id, priority: $priority, start_at: $start_at, target_end_at: $target_end_at, status: 'active', created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::create_milestone($tenant_id, $project_id, $key, $name, $description, $target_at, $completion_criteria) {
  LET $project = SELECT * FROM $project_id;
  IF count($project) = 0 THEN { THROW 'project_not_found'; };
  RETURN CREATE milestones CONTENT { tenant_id: $tenant_id, project_id: $project_id, key: $key, name: $name, description: $description, target_at: $target_at, completion_criteria: $completion_criteria, status: 'planned', created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::create_task($tenant_id, $project_id, $milestone_id, $application_id, $key, $title, $description, $priority, $assignee_ids, $required_outputs, $acceptance_criteria) {
  RETURN CREATE tasks CONTENT { tenant_id: $tenant_id, project_id: $project_id, milestone_id: $milestone_id, application_id: $application_id, key: $key, title: $title, description: $description, priority: $priority, assignee_ids: $assignee_ids, required_outputs: $required_outputs, acceptance_criteria: $acceptance_criteria, status: 'todo', created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::create_environment_configuration($tenant_id, $key, $name, $scope_kind, $scope_ref, $runtime_environment, $secrets_policy, $network_policy, $data_access_policy, $observability_policy) {
  RETURN CREATE environment_configurations CONTENT { tenant_id: $tenant_id, key: $key, name: $name, scope_kind: $scope_kind, scope_ref: $scope_ref, runtime_environment: $runtime_environment, secrets_policy: $secrets_policy, network_policy: $network_policy, data_access_policy: $data_access_policy, observability_policy: $observability_policy, enabled: true, created_at: time::now() };
};

DEFINE FUNCTION fn::create_tool_configuration($tenant_id, $key, $name, $scope_kind, $scope_ref, $allowed_tools, $denied_tools, $tool_settings, $tool_approval_policy, $max_tool_calls) {
  RETURN CREATE tool_configurations CONTENT { tenant_id: $tenant_id, key: $key, name: $name, scope_kind: $scope_kind, scope_ref: $scope_ref, allowed_tools: $allowed_tools, denied_tools: $denied_tools, tool_settings: $tool_settings, tool_approval_policy: $tool_approval_policy, max_tool_calls: $max_tool_calls, enabled: true, created_at: time::now() };
};

DEFINE FUNCTION fn::create_collaboration_space($tenant_id, $key, $name, $scope_kind, $scope_ref, $human_participant_ids, $agent_participant_ids, $application_ids, $collaboration_policy, $shared_context) {
  RETURN CREATE collaboration_spaces CONTENT { tenant_id: $tenant_id, key: $key, name: $name, scope_kind: $scope_kind, scope_ref: $scope_ref, human_participant_ids: $human_participant_ids, agent_participant_ids: $agent_participant_ids, application_ids: $application_ids, collaboration_policy: $collaboration_policy, shared_context: $shared_context, status: 'active', created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::assign_configurations($scope_ref, $environment_config_id, $tool_config_id, $collaboration_space_id) {
  LET $scope = SELECT * FROM $scope_ref;
  IF count($scope) = 0 THEN { THROW 'configuration_scope_not_found'; };
  UPDATE $scope_ref SET default_environment_config_id = $environment_config_id, default_tool_config_id = $tool_config_id, default_collaboration_space_id = $collaboration_space_id, updated_at = time::now();
  RETURN SELECT * FROM $scope_ref;
};

DEFINE FUNCTION fn::resolve_execution_configuration($tenant_id, $application_id, $project_id, $milestone_id, $task_id, $actor_id) {
  LET $application = IF $application_id = NONE THEN [] ELSE SELECT * FROM $application_id END;
  LET $project = IF $project_id = NONE THEN [] ELSE SELECT * FROM $project_id END;
  LET $milestone = IF $milestone_id = NONE THEN [] ELSE SELECT * FROM $milestone_id END;
  LET $task = IF $task_id = NONE THEN [] ELSE SELECT * FROM $task_id END;

  LET $env_id = IF count($task) > 0 AND $task[0].default_environment_config_id != NONE THEN $task[0].default_environment_config_id ELSE IF count($milestone) > 0 AND $milestone[0].default_environment_config_id != NONE THEN $milestone[0].default_environment_config_id ELSE IF count($project) > 0 AND $project[0].default_environment_config_id != NONE THEN $project[0].default_environment_config_id ELSE IF count($application) > 0 THEN $application[0].default_environment_config_id ELSE NONE END END END;
  LET $tool_id = IF count($task) > 0 AND $task[0].default_tool_config_id != NONE THEN $task[0].default_tool_config_id ELSE IF count($milestone) > 0 AND $milestone[0].default_tool_config_id != NONE THEN $milestone[0].default_tool_config_id ELSE IF count($project) > 0 AND $project[0].default_tool_config_id != NONE THEN $project[0].default_tool_config_id ELSE IF count($application) > 0 THEN $application[0].default_tool_config_id ELSE NONE END END END;
  LET $space_id = IF count($task) > 0 AND $task[0].default_collaboration_space_id != NONE THEN $task[0].default_collaboration_space_id ELSE IF count($milestone) > 0 AND $milestone[0].default_collaboration_space_id != NONE THEN $milestone[0].default_collaboration_space_id ELSE IF count($project) > 0 AND $project[0].default_collaboration_space_id != NONE THEN $project[0].default_collaboration_space_id ELSE IF count($application) > 0 THEN NONE ELSE NONE END END END;

  LET $env = IF $env_id = NONE THEN [] ELSE SELECT * FROM $env_id END;
  LET $tool = IF $tool_id = NONE THEN [] ELSE SELECT * FROM $tool_id END;
  LET $space = IF $space_id = NONE THEN [] ELSE SELECT * FROM $space_id END;

  LET $decision_log = fn::log_decision_context($tenant_id, 'execution_configuration_resolution', string::concat($task_id), $actor_id, NONE, NONE, { application_id: $application_id, project_id: $project_id, milestone_id: $milestone_id, task_id: $task_id }, {}, {}, {}, {}, {}, {}, { environment_config_id: $env_id, tool_config_id: $tool_id, collaboration_space_id: $space_id }, [{ kind: 'configuration_precedence', order: ['task', 'milestone', 'project', 'application'] }], { precedence: 'task_over_milestone_over_project_over_application' }, [{ env_id: $env_id, tool_id: $tool_id, space_id: $space_id }], { environment_config_id: $env_id, tool_config_id: $tool_id, collaboration_space_id: $space_id }, [], 'effective_execution_configuration_resolved', { method: 'agx:configuration-resolution-v1', precedence: ['task', 'milestone', 'project', 'application'] }, [], NONE, [], false);

  RETURN CREATE effective_execution_configurations CONTENT { tenant_id: $tenant_id, application_id: $application_id, project_id: $project_id, milestone_id: $milestone_id, task_id: $task_id, environment_config_id: $env_id, tool_config_id: $tool_id, collaboration_space_id: $space_id, effective_environment: IF count($env) = 0 THEN {} ELSE $env[0] END, effective_tools: IF count($tool) = 0 THEN {} ELSE $tool[0] END, effective_collaboration: IF count($space) = 0 THEN {} ELSE $space[0] END, resolution_order: ['task', 'milestone', 'project', 'application'], decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::require_tool_allowed_by_configuration($effective_config_id, $tool_key) {
  LET $config = SELECT * FROM $effective_config_id;
  IF count($config) = 0 THEN { THROW 'effective_configuration_not_found'; };
  LET $tools = $config[0].effective_tools;
  IF $tool_key INSIDE $tools.denied_tools THEN { THROW 'tool_denied_by_configuration'; };
  IF count($tools.allowed_tools) > 0 AND !$tool_key INSIDE $tools.allowed_tools THEN { THROW 'tool_not_allowed_by_configuration'; };
  RETURN true;
};
