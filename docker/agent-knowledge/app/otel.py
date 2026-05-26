"""OpenTelemetry instrumentation — no-op when OTEL_EXPORTER_OTLP_ENDPOINT is unset."""
import logging
import os

logger = logging.getLogger(__name__)

_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "")
_SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "agent-knowledge")


def setup_otel(app) -> None:
    if not _ENDPOINT:
        logger.info("OTel export disabled (OTEL_EXPORTER_OTLP_ENDPOINT not set)")
        return
    try:
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor

        resource = Resource.create({"service.name": _SERVICE_NAME})
        provider = TracerProvider(resource=resource)
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=_ENDPOINT)))
        trace.set_tracer_provider(provider)
        FastAPIInstrumentor.instrument_app(app)
        logger.info("OTel tracing configured", extra={"endpoint": _ENDPOINT, "service": _SERVICE_NAME})
    except ImportError:
        logger.warning("OTel packages not installed; tracing skipped")
