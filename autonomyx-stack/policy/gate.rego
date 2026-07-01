package autonomyx.gate

default allow := false

allow if {
  input.identity.id != ""
  input.domain != "blocked"
  input.trust_score >= 0.5
}

deny[reason] if {
  input.identity.id == ""
  reason := "IDENTITY_REQUIRED"
}

deny[reason] if {
  input.domain == "blocked"
  reason := "DOMAIN_BLOCKED"
}

deny[reason] if {
  input.trust_score < 0.5
  reason := "TRUST_BELOW_THRESHOLD"
}
