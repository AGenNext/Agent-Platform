package io.agennext.console.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agents")
public class AgentController {

  @GetMapping
  public List<Map<String, Object>> list() {
    return List.of(
        Map.of("name", "research-agent", "workspace", "research", "image", "ghcr.io/agennext/research-agent:latest", "status", "running"),
        Map.of("name", "ops-agent", "workspace", "ops", "image", "ghcr.io/agennext/ops-agent:latest", "status", "running")
    );
  }

  @PostMapping
  @ResponseStatus(HttpStatus.ACCEPTED)
  public Map<String, Object> create(@Valid @RequestBody CreateAgentRequest request) {
    return Map.of(
        "accepted", true,
        "operation", "deploy-agent",
        "workspace", request.workspace(),
        "name", request.name(),
        "image", request.image(),
        "replicas", request.replicas()
    );
  }

  @PostMapping("/{workspace}/{name}/restart")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public Map<String, Object> restart(@PathVariable String workspace, @PathVariable String name) {
    return Map.of("accepted", true, "operation", "restart-agent", "workspace", workspace, "name", name);
  }

  @DeleteMapping("/{workspace}/{name}")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public Map<String, Object> delete(@PathVariable String workspace, @PathVariable String name) {
    return Map.of("accepted", true, "operation", "delete-agent", "workspace", workspace, "name", name);
  }

  public record CreateAgentRequest(
      @NotBlank String name,
      @NotBlank String workspace,
      @NotBlank String image,
      @Positive int replicas
  ) {}
}
