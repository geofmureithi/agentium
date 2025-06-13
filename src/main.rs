use std::collections::HashMap;
use serde::{Deserialize, Serialize};

#[tokio::main]
async fn main() {
    println!("Hello, world!");
}

/// Represents the result of an agent action
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AgentResult {
    Success(String),
    Error(String),
    Partial(String, f32), // message and progress (0.0-1.0)
}

/// Represents different types of messages agents can send/receive
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AgentMessage {
    Task {
        id: String,
        content: String,
        metadata: HashMap<String, String>,
    },
    Response {
        task_id: String,
        result: AgentResult,
        metadata: HashMap<String, String>,
    },
    Query {
        id: String,
        query: String,
        response_to: Option<String>,
    },
    Broadcast {
        sender: String,
        content: String,
        tags: Vec<String>,
    },
    Heartbeat {
        agent_id: String,
        status: String,
        timestamp: u64,
    },
}

/// Configuration for agent initialization
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentConfig {
    pub agent_id: String,
    pub agent_type: String,
    pub capabilities: Vec<String>,
    pub max_concurrent_tasks: usize,
    pub settings: HashMap<String, String>,
}

/// Current status of an agent
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AgentStatus {
    Idle,
    Busy(String), // task description
    Error(String),
    Shutdown,
}

/// Metadata about the agent
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentInfo {
    pub id: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub capabilities: Vec<String>,
    pub supported_message_types: Vec<String>,
    pub status: AgentStatus,
}

/// Main trait that all agent plugins must implement
// #[plugy::plugin]
pub trait Agent {
    /// Initialize the agent with configuration
    fn initialize(&mut self, config: AgentConfig) -> Result<(), String>;
    
    /// Get agent information and current status
    fn get_info(&self) -> AgentInfo;
    
    /// Process an incoming message
    fn handle_message(&mut self, message: AgentMessage) -> Result<Option<AgentMessage>, String>;
    
    /// Execute a specific task
    fn execute_task(&mut self, task_id: String, task_data: String) -> Result<AgentResult, String>;
    
    /// Check if agent can handle a specific capability
    fn can_handle(&self, capability: &str) -> bool;
    
    /// Get current agent status
    fn get_status(&self) -> AgentStatus;
    
    /// Shutdown the agent gracefully
    fn shutdown(&mut self) -> Result<(), String>;
    
}
