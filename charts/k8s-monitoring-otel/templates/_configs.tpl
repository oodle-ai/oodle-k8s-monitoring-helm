{{/* OpenTelemetry Collector config */}}
{{- define "otelcol-config" -}}
receivers:
  prometheus:
    config:
      scrape_configs:
        {{- if (index .Values.metrics "kube-state-metrics").enabled }}
          {{- include "otelcol.config.scrape_config.kube_state_metrics" . | indent 8 }}
        {{- end }}
        {{- if (index .Values.metrics "node-exporter").enabled }}
          {{- include "otelcol.config.scrape_config.node_exporter" . | indent 8 }}
        {{- end }}

extensions:
  # The health_check extension is mandatory for this chart.
  # Without the health_check extension the collector will fail the readiness and liveliness probes.
  # The health_check extension can be modified, but should never be removed.
  health_check: {}
  memory_ballast: {}
  {{- if .Values.metrics.enabled }}
    {{ include "otelcol.config.extension.metricsServiceAuth" . | indent 2 }}
  {{- end }}

processors:
  batch: {}

exporters:
  debug: {}
  {{- if .Values.metrics.enabled }}
    {{ include "otelcol.config.exporter.metricsService" . | indent 2 }}
  {{- end }}

service:
  telemetry:
    metrics:
      address: ${env:MY_POD_IP}:8888
  extensions:
    - health_check
    - memory_ballast
    - {{ include "otelcol.config.extension_name.metricsServiceAuth" . }}
  pipelines:
    metrics:
      receivers:
        - prometheus
      processors:
        - batch
      exporters:
        - {{ include "otelcol.config.exporter_name.metricsService" . }}
{{- end -}}
