
CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    agent_type TEXT NOT NULL,
    description TEXT,
    system_prompt TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version TEXT,
    status TEXT DEFAULT 'active',
    metadata JSON,
    llm_config JSON,
    embedding_config JSON,
    tool_config JSON
);

CREATE TABLE core_memory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    label TEXT NOT NULL, -- 'persona', 'human', 'context', custom labels
    content TEXT NOT NULL,
    char_limit INTEGER DEFAULT 5000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_template BOOLEAN DEFAULT FALSE,
    template_name TEXT,
    priority INTEGER DEFAULT 0, -- For ordering/importance
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    UNIQUE(agent_id, label)
);

-- Archival memory (infinite size, searchable)
CREATE TABLE archival_memory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    content TEXT NOT NULL,
    content_type TEXT DEFAULT 'text', -- text, json, structured
    tags TEXT, -- Comma-separated tags for categorization
    embedding BLOB, -- Vector embedding for semantic search
    embedding_model TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    importance_score REAL DEFAULT 0.5, -- 0-1 scale for memory importance
    access_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP,
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
);

CREATE TABLE conversations (
    id TEXT PRIMARY KEY,
    agent_id TEXT NOT NULL,
    title TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    status TEXT DEFAULT 'active', -- active, completed, archived
    context_summary TEXT, -- AI-generated summary of conversation
    participant_count INTEGER DEFAULT 2,
    metadata JSON,
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
);

-- Messages with rich context
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    role TEXT NOT NULL, -- system, user, assistant, tool
    content TEXT NOT NULL,
    content_type TEXT DEFAULT 'text', -- text, json, function_call, tool_response
    
    -- Message metadata
    model TEXT,
    token_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Contextual information
    in_context BOOLEAN DEFAULT TRUE, -- Whether message is in current context window
    context_priority INTEGER DEFAULT 0,
    embedding BLOB,
    
    -- Tool/function call data
    tool_calls JSON,
    tool_returns JSON,
    
    -- Message relationships
    parent_message_id TEXT,
    thread_id TEXT,
    
    -- Metadata for flexibility
    metadata JSON,
    
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_message_id) REFERENCES messages(id)
);

-- Context windows - what's currently "in mind"
CREATE TABLE context_windows (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    conversation_id TEXT,
    window_type TEXT NOT NULL, -- 'active', 'working', 'background'
    
    -- Window configuration
    max_tokens INTEGER DEFAULT 32000,
    current_tokens INTEGER DEFAULT 0,
    priority_threshold REAL DEFAULT 0.5,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE SET NULL
);

-- Items in context windows (messages, memories, etc.)
CREATE TABLE context_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    context_window_id INTEGER NOT NULL,
    item_type TEXT NOT NULL, -- 'message', 'core_memory', 'archival_memory', 'tool_result'
    item_id TEXT NOT NULL, -- ID of the referenced item
    position INTEGER NOT NULL,
    token_count INTEGER DEFAULT 0,
    priority_score REAL DEFAULT 0.5,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (context_window_id) REFERENCES context_windows(id) ON DELETE CASCADE
);

-- ============================================================================
-- TOOLS AND CAPABILITIES
-- ============================================================================

-- Tool definitions
CREATE TABLE tools (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    tool_type TEXT NOT NULL,
    source_code TEXT,
    json_schema JSON NOT NULL,
    return_char_limit INTEGER DEFAULT 1000000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tags TEXT,
    metadata JSON
);

-- Agent-tool relationships
CREATE TABLE agent_tools (
    agent_id TEXT NOT NULL,
    tool_id TEXT NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    tool_rules JSON, -- Custom rules for this agent-tool combo
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (agent_id, tool_id),
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (tool_id) REFERENCES tools(id) ON DELETE CASCADE
);

-- Tool execution history
CREATE TABLE tool_executions (
    id TEXT PRIMARY KEY,
    agent_id TEXT NOT NULL,
    tool_id TEXT NOT NULL,
    message_id TEXT,
    
    -- Execution details
    function_name TEXT NOT NULL,
    arguments JSON,
    result TEXT,
    execution_time_ms INTEGER,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (tool_id) REFERENCES tools(id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE SET NULL
);

-- Learned patterns and insights
CREATE TABLE agent_knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    knowledge_type TEXT NOT NULL, -- 'pattern', 'preference', 'fact', 'relationship'
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    confidence_score REAL DEFAULT 0.5,
    source_type TEXT, -- 'conversation', 'observation', 'explicit'
    source_id TEXT, -- ID of source (message, conversation, etc.)
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_reinforced TIMESTAMP,
    reinforcement_count INTEGER DEFAULT 1,
    
    embedding BLOB,
    tags TEXT,
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
);

CREATE TABLE entities (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    entity_type TEXT NOT NULL, -- 'person', 'organization', 'concept', 'location'
    description TEXT,
    attributes JSON, -- Flexible attributes storage
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE agent_entity_relationships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    relationship_type TEXT NOT NULL, -- 'user', 'colleague', 'customer', 'knows_about'
    strength REAL DEFAULT 0.5, -- Relationship strength 0-1
    context TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE,
    UNIQUE(agent_id, entity_id, relationship_type)
);

CREATE TABLE agent_states (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    state_type TEXT NOT NULL, -- 'emotional', 'behavioral', 'cognitive'
    state_data JSON NOT NULL,
    confidence REAL DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP, -- Some states may be temporary
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
);

CREATE TABLE events (
    id TEXT PRIMARY KEY,
    agent_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_data JSON,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
);

CREATE TABLE conversation_analytics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    
    -- Metrics
    message_count INTEGER DEFAULT 0,
    avg_response_time_ms INTEGER,
    tool_usage_count INTEGER DEFAULT 0,
    user_satisfaction_score REAL,
    
    -- Computed at conversation end
    computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_agent ON messages(agent_id, created_at);
CREATE INDEX idx_messages_in_context ON messages(in_context, context_priority);
CREATE INDEX idx_archival_memory_agent ON archival_memory(agent_id, importance_score);
CREATE INDEX idx_archival_memory_tags ON archival_memory(tags);
CREATE INDEX idx_tool_executions_agent ON tool_executions(agent_id, executed_at);
CREATE INDEX idx_agent_knowledge_type ON agent_knowledge(agent_id, knowledge_type);
CREATE INDEX idx_events_agent ON events(agent_id, triggered_at, processed);

-- Full-text search indexes
CREATE VIRTUAL TABLE messages_fts USING fts5(
    content,
    content=messages,
    content_rowid=rowid
);

CREATE VIRTUAL TABLE archival_memory_fts USING fts5(
    content,
    tags,
    content=archival_memory,
    content_rowid=id
);

CREATE TRIGGER update_agent_timestamp 
AFTER UPDATE ON agents 
BEGIN
    UPDATE agents SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Update conversation when messages are added
CREATE TRIGGER update_conversation_on_message
AFTER INSERT ON messages
BEGIN
    UPDATE conversations 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.conversation_id;
END;

-- Maintain FTS indexes
CREATE TRIGGER messages_fts_insert AFTER INSERT ON messages BEGIN
    INSERT INTO messages_fts(rowid, content) VALUES (NEW.rowid, NEW.content);
END;

CREATE TRIGGER messages_fts_delete AFTER DELETE ON messages BEGIN
    DELETE FROM messages_fts WHERE rowid = OLD.rowid;
END;

CREATE TRIGGER messages_fts_update AFTER UPDATE ON messages BEGIN
    UPDATE messages_fts SET content = NEW.content WHERE rowid = NEW.rowid;
END;

CREATE VIEW current_context AS
SELECT 
    a.id as agent_id,
    a.name as agent_name,
    cm.label,
    cm.content,
    cm.updated_at
FROM agents a
JOIN core_memory cm ON a.id = cm.agent_id
WHERE a.status = 'active';

CREATE VIEW recent_conversations AS
SELECT 
    c.id,
    c.agent_id,
    a.name as agent_name,
    c.title,
    c.started_at,
    COUNT(m.id) as message_count,
    MAX(m.created_at) as last_message_at
FROM conversations c
JOIN agents a ON c.agent_id = a.id
LEFT JOIN messages m ON c.id = m.conversation_id
WHERE c.status = 'active'
GROUP BY c.id, c.agent_id, a.name, c.title, c.started_at
ORDER BY last_message_at DESC;

-- Agent performance summary
CREATE VIEW agent_performance AS
SELECT 
    a.id,
    a.name,
    COUNT(DISTINCT c.id) as total_conversations,
    COUNT(m.id) as total_messages,
    AVG(ca.user_satisfaction_score) as avg_satisfaction,
    COUNT(te.id) as total_tool_executions
FROM agents a
LEFT JOIN conversations c ON a.id = c.agent_id
LEFT JOIN messages m ON c.id = m.conversation_id
LEFT JOIN conversation_analytics ca ON c.id = ca.conversation_id
LEFT JOIN tool_executions te ON a.id = te.agent_id
GROUP BY a.id, a.name;
