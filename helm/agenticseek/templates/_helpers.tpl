{{/*
Expand the name of the chart.
*/}}
{{- define "agenticseek.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "agenticseek.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "agenticseek.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agenticseek.labels" -}}
helm.sh/chart: {{ include "agenticseek.chart" . }}
{{ include "agenticseek.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agenticseek.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agenticseek.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "agenticseek.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "agenticseek.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Backend labels
*/}}
{{- define "agenticseek.backend.labels" -}}
{{ include "agenticseek.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "agenticseek.frontend.labels" -}}
{{ include "agenticseek.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
SearXNG labels
*/}}
{{- define "agenticseek.searxng.labels" -}}
{{ include "agenticseek.labels" . }}
app.kubernetes.io/component: searxng
{{- end }}

{{/*
Redis labels
*/}}
{{- define "agenticseek.redis.labels" -}}
{{ include "agenticseek.labels" . }}
app.kubernetes.io/component: redis
{{- end }}
