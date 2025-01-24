steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/${project_id}/streamdata-generator', '.']
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'gcr.io/${project_id}/streamdata-generator']
logsBucket: '${tmp_bucket}'
serviceAccount: 'projects/${project_id}/serviceAccounts/${build_sa}'
