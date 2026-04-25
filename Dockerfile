# Dockerfile for ISE Diagnosis Automation Tool
FROM python:3.9-slim

# Install system dependencies for WeasyPrint/Playwright and Bash
RUN apt-get update && apt-get install -y \
    bash \
    grep \
    sed \
    coreutils \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    libffi-dev \
    libgobject-2.0-0 \
    shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements if any (we'll just install directly for simplicity)
RUN pip install weasyprint jinja2

# Copy project files
COPY . .

# Make scripts executable
RUN chmod +x main.sh runners/*.sh shell_scirpt/info_security_equip/*/*.sh

# Default command
ENTRYPOINT ["/bin/bash", "./main.sh"]
CMD ["ise", "--help"]
