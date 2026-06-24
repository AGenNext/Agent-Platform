package io.agennext.console.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
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
@RequestMapping("/api/workspaces")
public class WorkspaceController {

  @GetMapping
  public List<Map<String, Object>> list() {
    return List.of(
        Map.of("name", "research", "namespace", "research", "status", "active"),
        Map.of("name", "ops", "namespace", "ops", "status", "active")
    );
  }

  @PostMapping
  @ResponseStatus(HttpStatus.ACCEPTED)
  public Map<String, Object> create(@Valid @RequestBody CreateWorkspaceRequest request) {
    return Map.of(
        "accepted", true,
        "operation", "create-workspace",
        "namespace", request.name(),
        "next", "apply Namespace with agennext.io/managed-by=internal-agent-console"
    );
  }

  @DeleteMapping("/{name}")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public Map<String, Object> delete(@PathVariable String name) {
    return Map.of(
        "accepted", true,
        "operation", "delete-workspace",
        "namespace", name
    );
  }

  public record CreateWorkspaceRequest(@NotBlank String name, String description) {}
}
