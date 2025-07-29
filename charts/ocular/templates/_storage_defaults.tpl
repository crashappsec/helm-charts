
{{/*
This file is auto generated
DO NOT EDIT
*/}}

{{- define "crawlers.defaults" -}}

github: |
  image: ghcr.io/crashappsec/ocular-default-crawlers:v0.1.1
  secrets:
      - name: github-token
        mountType: envVar
        mountTarget: GITLAB_TOKEN
  parameters:
      DOWNLOADER:
          description: Override the downloader for the crawler. The default will be chosen based on the crawler type.
          required: false
      GITHUB_ORGS:
          description: Comma-separated list of GitLab groups to crawl.
          required: true
      PROFILE:
          description: Profile to use for the crawler.
          required: true
      SLEEP_DURATION:
          description: Duration to sleep between requests. Will be parsed as a time.Duration.
          required: false
          default: 1m

gitlab: |
  image: ghcr.io/crashappsec/ocular-default-crawlers:v0.1.1
  secrets:
      - name: gitlab-token
        mountType: envVar
        mountTarget: GITLAB_TOKEN
  parameters:
      DOWNLOADER:
          description: Override the downloader for the crawler. The default will be chosen based on the crawler type.
          required: false
      GITLAB_GROUPS:
          description: Comma-separated list of GitLab groups to crawl. If empty or not provided, the crawler will crawl all accessible projects on the instance.
          required: false
      GITLAB_INSTANCE_URL:
          description: Base URL of the GitLab instance to crawl. Defaults to 'https://gitlab.com'.
          required: false
          default: https://gitlab.com
      PROFILE:
          description: Profile to use for the crawler.
          required: true
      SLEEP_DURATION:
          description: Duration to sleep between requests. Will be parsed as a time.Duration.
          required: false
          default: 1m

static: |
  image: ghcr.io/crashappsec/ocular-default-crawlers:v0.1.1
  parameters:
      DOWNLOADER:
          description: Override the downloader for the crawler. The default will be chosen based on the crawler type.
          required: false
      PROFILE:
          description: Profile to use for the crawler.
          required: true
      SLEEP_DURATION:
          description: Duration to sleep between requests. Will be parsed as a time.Duration.
          required: false
          default: 1m
      TARGET_IDENTIFIERS:
          description: List of target identifiers to crawl. Should be a JSON array of strings.
          required: true

{{- end }}

{{- define "downloaders.defaults" -}}

docker: |
  image: ghcr.io/crashappsec/ocular-default-downloaders:v0.1.1
  secrets:
      - name: downloader-dockerconfig
        mountType: file
        mountTarget: /etc/docker/config.json
  env:
      - name: DOCKER_CONFIG
        value: /etc/docker

gcs: |
  image: ghcr.io/crashappsec/ocular-default-downloaders:v0.1.1
  secrets:
      - name: downloader-gcs-credentials
        mountType: file
        mountTarget: GOOGLE_APPLICATION_CREDENTIALS

git: |
  image: ghcr.io/crashappsec/ocular-default-downloaders:v0.1.1
  secrets:
      - name: downloader-gitconfig
        mountType: file
        mountTarget: /etc/gitconfig

npm: |
  image: ghcr.io/crashappsec/ocular-default-downloaders:v0.1.1

pypi: |
  image: ghcr.io/crashappsec/ocular-default-downloaders:v0.1.1

s3: |
  image: ghcr.io/crashappsec/ocular-default-downloaders:v0.1.1
  secrets:
      - name: downloader-aws-config
        mountType: file
        mountTarget: /etc/aws/config
  env:
      - name: AWS_CONFIG_FILE
        value: /etc/aws/config

{{- end }}

{{- define "uploaders.defaults" -}}

s3: |
  image: ghcr.io/crashappsec/ocular-default-uploaders:v0.1.1
  secrets:
      - name: uploader-awsconfig
        mountType: file
        mountTarget: /aws/config
  parameters:
      BUCKET:
          description: Name of the S3 bucket to upload to.
          required: true
      REGION:
          description: AWS region of the S3 bucket. Defaults to the region configured in the AWS SDK.
          required: false
      SUBFOLDER:
          description: Subfolder in the S3 bucket to upload files to. Defaults to the root of the bucket.
          required: false

webhook: |
  image: ghcr.io/crashappsec/ocular-default-uploaders:v0.1.1
  parameters:
      METHOD:
          description: The HTTP method to use for the webhook request. Defaults to PUT.
          required: false
          default: PUT
      URL:
          description: URL of the webhook to send data to.
          required: true

{{- end }}

