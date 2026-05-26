FROM python:3.11-slim

WORKDIR /workspace

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ src/

ENV PYTHONPATH=/workspace/src
ENV PYTHONUNBUFFERED=1

# Default: run the memory agent in interactive mode.
# Override CMD to run researcher or orchestrator.
CMD ["python", "src/memory_agent.py"]
