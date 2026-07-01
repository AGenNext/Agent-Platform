export type TelemetryEvent = {
  name: string;
  timestamp: string;
  attributes: Record<string, string | number | boolean | undefined>;
};

export function emitTelemetry(event: Omit<TelemetryEvent, "timestamp">): TelemetryEvent {
  const record: TelemetryEvent = {
    ...event,
    timestamp: new Date().toISOString(),
  };

  // First implementation writes structured events to stdout.
  // Production binding should export this through OpenTelemetry SDK + collector.
  console.log(JSON.stringify({ telemetry: record }));
  return record;
}

export function admissionTelemetry(input: {
  uid: string;
  kind?: string;
  name?: string;
  namespace?: string;
  allowed: boolean;
  reason?: string;
}): TelemetryEvent {
  return emitTelemetry({
    name: "autonomyx.admission.decision",
    attributes: {
      uid: input.uid,
      kind: input.kind,
      name: input.name,
      namespace: input.namespace,
      allowed: input.allowed,
      reason: input.reason,
    },
  });
}
