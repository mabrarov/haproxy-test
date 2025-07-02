{{/*
Expand the name of the chart.
*/}}
{{- define "blackbox-test.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "blackbox-test.fullname" -}}
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
{{- define "blackbox-test.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common selector labels
*/}}
{{- define "blackbox-test.matchLabels" -}}
app.kubernetes.io/name: {{ include "blackbox-test.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "blackbox-test.labels" -}}
helm.sh/chart: {{ include "blackbox-test.chart" . | quote }}
{{ include "blackbox-test.matchLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app: {{ include "blackbox-test.fullname" . | quote }}
{{- end }}

{{/*
Docker authentication config for image registry.
Usage:
{{ include "blackbox-test.dockerRegistryAuthenticationConfig" (dict "imageRegistry" .Values.backend.image.registry "credentials" .Values.backend.image.pullSecret) }}
*/}}
{{- define "blackbox-test.dockerRegistryAuthenticationConfig" -}}
{{- $registry := .imageRegistry }}
{{- $username := .credentials.username }}
{{- $password := .credentials.password }}
{{- $email := .credentials.email }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" $registry $username $password $email (printf "%s:%s" $username $password | b64enc) | b64enc }}
{{- end }}

{{/*
Backend component labels
*/}}
{{- define "blackbox-test.backend.componentLabels" -}}
app.kubernetes.io/component: "backend"
{{- end }}

{{/*
Name of backend deployment.
*/}}
{{- define "blackbox-test.backend.deploymentName" -}}
{{ include "blackbox-test.fullname" . }}-backend
{{- end }}

{{/*
Name of backend service.
*/}}
{{- define "blackbox-test.backend.serviceName" -}}
{{ include "blackbox-test.fullname" . }}-backend
{{- end }}

{{/*
Name of backend image pull secret.
*/}}
{{- define "blackbox-test.backend.imagePullSecretName" -}}
{{ include "blackbox-test.fullname" . }}-backend
{{- end }}

{{/*
Name of backend ingress.
*/}}
{{- define "blackbox-test.backend.ingressName" -}}
{{ include "blackbox-test.fullname" . }}-backend
{{- end }}

{{/*
Name of backend container port.
*/}}
{{- define "blackbox-test.backend.containerPortName" -}}
http
{{- end }}

{{/*
Name of backend service port.
*/}}
{{- define "blackbox-test.backend.servicePortName" -}}
http
{{- end }}

{{/*
Backend container image tag.
*/}}
{{- define "blackbox-test.backend.imageTag" -}}
{{ .Values.backend.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Backend container image full name.
*/}}
{{- define "blackbox-test.backend.imageFullName" -}}
{{ printf "%s/%s:%s" .Values.backend.image.registry .Values.backend.image.repository (include "blackbox-test.backend.imageTag" . ) }}
{{- end }}

{{/*
Backbox component labels
*/}}
{{- define "blackbox-test.blackbox.componentLabels" -}}
app.kubernetes.io/component: "blackbox"
{{- end }}

{{/*
Name of blackbox deployment.
*/}}
{{- define "blackbox-test.blackbox.deploymentName" -}}
{{ include "blackbox-test.fullname" . }}-blackbox
{{- end }}

{{/*
Name of blackbox service.
*/}}
{{- define "blackbox-test.blackbox.serviceName" -}}
{{ include "blackbox-test.fullname" . }}-blackbox
{{- end }}

{{/*
Name of blackbox image pull secret.
*/}}
{{- define "blackbox-test.blackbox.imagePullSecretName" -}}
{{ include "blackbox-test.fullname" . }}-blackbox
{{- end }}

{{/*
Name of blackbox ingress.
*/}}
{{- define "blackbox-test.blackbox.ingressName" -}}
{{ include "blackbox-test.fullname" . }}-blackbox
{{- end }}

{{/*
Name of blackbox container port.
*/}}
{{- define "blackbox-test.blackbox.containerPortName" -}}
http
{{- end }}

{{/*
Name of blackbox service port.
*/}}
{{- define "blackbox-test.blackbox.servicePortName" -}}
http
{{- end }}

{{/*
Blackbox container image tag.
*/}}
{{- define "blackbox-test.blackbox.imageTag" -}}
{{ .Values.blackbox.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Blackbox container image full name.
*/}}
{{- define "blackbox-test.blackbox.imageFullName" -}}
{{ printf "%s/%s:%s" .Values.blackbox.image.registry .Values.blackbox.image.repository (include "blackbox-test.blackbox.imageTag" . ) }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "blackbox-test.tplValuesRender" (dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "blackbox-test.tplValuesRender" -}}
{{- if typeIs "string" .value }}
{{- tpl .value .context }}
{{- else }}
{{- tpl (.value | toYaml) .context }}
{{- end }}
{{- end -}}
