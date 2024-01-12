{{/* OpenTelemetry Collector config */}}
{{- define "otelcol-config" -}}
extensions:
  # The health_check extension is mandatory for this chart.
  # Without the health_check extension the collector will fail the readiness and liveliness probes.
  # The health_check extension can be modified, but should never be removed.
  health_check: {}
  memory_ballast: {}
{{- if .Values.metrics.enabled }}
  {{ include "otelcol.config.extension.metricsServiceAuth" . | indent 2 }}
{{- end }}
{{- if .Values.cluster_events.enabled }}
  {{ include "otelcol.config.extension.logsServiceAuth" . | indent 2 }}
{{- end }}

receivers:
{{- if .Values.metrics.enabled }}
  prometheus:
    config:
      scrape_configs:
      {{- if .Values.metrics.collector.enabled }}
        {{- include "otelcol.config.scrape_config.collector" . | indent 8 }}
      {{- end }}
      {{- if (index .Values.metrics "kube-state-metrics").enabled }}
        {{- include "otelcol.config.scrape_config.kube_state_metrics" . | indent 8 }}
      {{- end }}
      {{- if (index .Values.metrics "node-exporter").enabled }}
        {{- include "otelcol.config.scrape_config.node_exporter" . | indent 8 }}
      {{- end }}
      {{- if .Values.metrics.kubelet.enabled }}
        {{- include "otelcol.config.scrape_config.kubelet" . | indent 8 }}
      {{- end }}
      {{- if .Values.metrics.cadvisor.enabled }}
        {{- include "otelcol.config.scrape_config.cadvisor" . | indent 8 }}
      {{- end }}
{{- end }}
{{- if .Values.cluster_events.enabled }}
  {{ include "otelcol.config.receiver.cluster_events" . | indent 2 }}
{{- end }}

processors:
  batch: {}

exporters:
  debug:
    verbosity: basic
{{- if .Values.metrics.enabled }}
  {{ include "otelcol.config.exporter.metricsService" . | indent 2 }}
{{- end }}
{{- if .Values.cluster_events.enabled }}
  {{ include "otelcol.config.exporter.logsService" . | indent 2 }}
{{- end }}

service:
  telemetry:
    logs:
      level: "debug"
    metrics:
      address: ${env:MY_POD_IP}:8888
  extensions:
    - health_check
    - memory_ballast
{{- if .Values.metrics.enabled }}
    - {{ include "otelcol.config.extension_name.metricsServiceAuth" . }}
{{- end }}
{{- if .Values.cluster_events.enabled }}
    - {{ include "otelcol.config.extension_name.logsServiceAuth" . }}
{{- end }}
  pipelines:
{{- if .Values.metrics.enabled }}
    metrics:
      receivers:
        - prometheus
      processors:
        - batch
      exporters:
        - debug
        - {{ include "otelcol.config.exporter_name.metricsService" . }}
{{- end }}
{{- if .Values.cluster_events.enabled }}
    logs:
      receivers:
        - {{ include "otelcol.config.receiver_name.cluster_events" . }}
      exporters:
        - debug
        - {{ include "otelcol.config.exporter_name.logsService" . }}
{{- end }}
{{- end -}}




{{/* OpenTelemetry Collector Node config */}}
{{- define "otelcol-node-config" -}}
extensions:
  # The health_check extension is mandatory.
  # Without the health_check extension the collector will fail the readiness and liveliness probes.
  # The health_check extension can be modified, but should never be removed.
  health_check: {}
  memory_ballast: {}
{{- if .Values.metrics.enabled }}
  {{ include "otelcol.config.extension.metricsServiceAuth" . | indent 2 }}
{{- end }}
{{- if .Values.logs.enabled }}
  {{ include "otelcol.config.extension.logsServiceAuth" . | indent 2 }}
{{- end }}

receivers:
{{- if .Values.metrics.hostmetrics.enabled }}
  {{ include "otelcol.config.receiver.hostmetrics" . | indent 2 }}
{{- end }}
{{- if .Values.logs.enabled }}
  {{ include "otelcol.config.receiver.pod_logs" . | indent 2 }}
{{- end }}
{{- if .Values.metrics.enabled }}
  prometheus:
    config:
      scrape_configs:
      {{- if .Values.metrics.collector.enabled }}
        {{- include "otelcol.config.scrape_config.collector" . | indent 8 }}
      {{- end }}
{{- end }}

processors:
  batch: {}
  {{ include "otelcol.config.resource.pod_logs" . | indent 2 }}
  {{ include "otelcol.config.transform.pod_logs" . | indent 2 }}
{{- if .Values.metrics.hostmetrics.enabled }}
  {{ include "otelcol.config.processor.hostmetrics" . | indent 2 }}
{{- end }}

exporters:
  debug:
    verbosity: basic
{{- if .Values.metrics.enabled }}
    {{ include "otelcol.config.exporter.metricsService" . | indent 2 }}
{{- end }}
{{- if .Values.logs.enabled }}
  {{ include "otelcol.config.exporter.logsService" . | indent 2 }}
{{- end }}

service:
  extensions:
    - health_check
{{- if .Values.logs.enabled }}
    - {{ include "otelcol.config.extension_name.logsServiceAuth" . }}
{{- end }}
{{- if .Values.metrics.hostmetrics.enabled }}
    - {{ include "otelcol.config.extension_name.metricsServiceAuth" . }}
{{- end }}
  pipelines:
{{- if .Values.metrics.enabled }}
    metrics:
      receivers:
{{- if .Values.metrics.hostmetrics.enabled }}
        - {{ include "otelcol.config.receiver_name.hostmetrics" . }}
{{- end }}
        - prometheus
      processors:
        - batch
        - {{ include "otelcol.config.processor_name.hostmetrics" . }}
      exporters:
        - debug
        - {{ include "otelcol.config.exporter_name.metricsService" . }}
{{- end }}
{{- if .Values.logs.enabled }}
    logs/podLogs:
      receivers:
        - {{ include "otelcol.config.receiver_name.pod_logs" . }}
      processors:
        - batch
        - {{ include "otelcol.config.transform_name.pod_logs" . }}
        - {{ include "otelcol.config.resource_name.pod_logs" . }}
      exporters:
        - {{ include "otelcol.config.exporter_name.logsService" . }}
{{- end }}

  telemetry:
    logs:
      level: 'debug'
{{- end -}}
