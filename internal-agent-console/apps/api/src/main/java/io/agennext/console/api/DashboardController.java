package io.agennext.console.api;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

  @GetMapping
  public Map<String, Object> dashboard() {
    return Map.of(
        "workspaces", 3,
        "agents", 12,
        "deployments", 9,
        "secrets", 6,
        "cluster", "connected",
        "mode", "internal-only"
    );
  }
}
