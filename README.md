# agentium - Agent2Agent Framework

[![License: GPL3](https://img.shields.io/badge/License-GPL3-yellow.svg)](https://opensource.org/license/gpl-3-0)
[![Rust](https://img.shields.io/badge/Rust-1.60%2B-blue)](https://www.rust-lang.org/)
[![Wasm](https://img.shields.io/badge/WebAssembly-654FF0?logo=webassembly&logoColor=fff)](https://webassembly.org/)

---

Agentium is a rust based framework for building interoperable agents using WASM, following the Agent-to-Agent protocol standards. It enables secure, vendor-neutral communication between autonomous agents in distributed systems.


## Features

- 🧩 Agents as WebAssembly modules
- 🔐 End-to-end encrypted communication
- 📄 `agent.toml` for describing agent interfaces
- 🧠 Workflow orchestration via DAG traits
- 🌐 Cross-host agent communication
- 📦 Standards-compliant with Agent-to-Agent protocol standards


## Architecture

- **Agent**: A Wasm module + `agent.toml`, implements a common `Agent` trait via [`plugy`](https://github.com/geofmureithi/plugy)
- **Host**: Loads agents, exposes host functions, manages secure messaging.
- **DAG Engine**: Agents can emit DAG-based workflows for execution via [`apalis`](https://github.com/geofmureithi/apalis)
- **Web UI**: Optional web interface.

## Example Agent
*This is a basic example and will possibly change*
```rs
// Weather Agent
#[agentium_core::agent]
struct WeatherAgent {
    location: String,
}

impl Agent for WeatherAgent {
    fn handle_message(&mut self, msg: Message) -> Result<Message, AgentError> {
        // Process weather request and return forecast
        Ok(Message::new("forecast", "sunny"))
    }
}

// Travel Planner Agent
#[agentium_core::agent]
struct TravelPlanner {
    destination: String,
}

impl Agent for TravelPlanner {
    fn handle_message(&mut self, msg: Message) -> Result<Message, AgentError> {
        // Query weather agent before planning
        let forecast = self.query_agent("weather_agent", Message::new("request", &self.destination))?;
        Ok(Message::new("itinerary", format!("Plan for {} weather", forecast)))
    }
}
```


## Roadmap

- [ ] Core agent runtime implementation
- [ ] Host function interface
- [ ] TOML configuration parser
- [ ] Encryption layer
- [ ] Example agents
- [ ] Benchmarking suite

## Contributing

Contributions are welcome!

## License

Agentium is licensed under the GPL3 License.
