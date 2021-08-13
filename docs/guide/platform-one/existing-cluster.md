# Big-Bang installation on pre-existing cluster

This tutorial shows how to install Big Bang on a pre-existing cluster.

# Prerequisites

- [Capact Cluster](https://capact.io/docs/installation/) from the latest `main`.
- [Capact CLI](https://capact.io/docs/cli/getting-started/)
- [jq](https://stedolan.github.io/jq/download/)

# Capact setup

1. Ensure that the built-in runner execution timeout is set to minimum 1h:

   To check current timeout, run:
   ```bash
   kubectl get deploy -n capact-system capact-engine -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name == "APP_BUILTIN_RUNNER_TIMEOUT")].value}'
   ```

   If the output is empty, or returned value is lower that 1h, run:
   ```bash
   kubectl set env deploy/capact-engine -n capact-system -c engine APP_BUILTIN_RUNNER_TIMEOUT=3h
   ```

1. Ensure that the [StructsureLabs/commercial-hub-manifests](https://github.com/StructsureLabs/commercial-hub-manifests) manifests are used:

   To check current manifest path, run:
   ```bash
   kubectl get deploy -n capact-system capact-hub-public -o jsonpath='{.spec.template.spec.containers[?(@.name == "hub-public-populator")].env[?(@.name == "MANIFESTS_PATH")].value}'
   ```

   If the manifest path is not set for [StructsureLabs/commercial-hub-manifests](https://github.com/StructsureLabs/commercial-hub-manifests), run:
   ```bash
   # Export read-only ssh key than can be used by populator to download manifest from private repository
   export COMMERCIAL_HUB_MANIFESTS_SSH_KEY=LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUFNd0FBQUF0emMyZ3RaVwpReU5UVXhPUUFBQUNDMUVQb3pBRktxeFMveDJXVWxWTGhNOEs3UWVvd0g0L2t5MzdZTUlMZXFUZ0FBQUppQVVjSmJnRkhDCld3QUFBQXR6YzJndFpXUXlOVFV4T1FBQUFDQzFFUG96QUZLcXhTL3gyV1VsVkxoTThLN1Flb3dINC9reTM3WU1JTGVxVGcKQUFBRUN5bllWQTl5YjVCWHdtYVRTOUtZalpxSzZGZDJHL1ZBcTdGdVJaLy9oVkI3VVErak1BVXFyRkwvSFpaU1ZVdUV6dwpydEI2akFmaitUTGZ0Z3dndDZwT0FBQUFFV052Ym5SaFkzUkFZMkZ3WVdOMExtbHZBUUlEQkE9PQotLS0tLUVORCBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0K
   kubectl set env deploy/capact-hub-public -n capact-system -c hub-public-populator MANIFESTS_PATH="git@github.com:StructsureLabs/commercial-hub-manifests.git?ref=main&sshkey=${COMMERCIAL_HUB_MANIFESTS_SSH_KEY}"
   ```

1. Define TypeInstances which describe your cluster and hold kubeconfig:

   >**NOTE:** You can skip this step if you have already a kubeconfig TypeInstance in you cluster that you want to use.
   >

   ```bash
   export SERVER_URL={url} # e.g https://152.70.166.40:6443
   export NAME={name} # e.g stage
   export K8S_TYPE={type} # e.g rke2, k3d, etc.
   export K8S_VERSION={version} # e.g v1.20.5
   export KUBECONFIG_PATH={path} # e.g. ~/.kube/config
   cat > /tmp/cluster.yaml << ENDOFFILE
   typeInstances:
     - alias: "cluster"
       typeRef:
         path: cap.type.containerization.kubernetes.cluster
         revision: 0.1.0
       value:
         apiServerUrl: "${SERVER_URL}"
         name: "${NAME}"
         type: "${K8S_TYPE}"
         version: "${K8S_VERSION}"
     - alias: "kubeconfig"
       typeRef:
         path: cap.type.containerization.kubernetes.kubeconfig
         revision: 0.1.0
       value:
         config:
           # kubeconfig to existing cluster that was described above
   $(cat $KUBECONFIG_PATH | sed 's/^/        /')
   usesRelations:
     - from: cluster
       to: kubeconfig
   ENDOFFILE
   ```

1. Create the cluster TypeInstances and export kubeconfig TypeInstance ID:

    ```bash
    export KUBECONFIG_TI=$(capact ti create -f /tmp/cluster.yaml -ojson | jq -r '.[] | select(.alias == "kubeconfig") | .id')
    ```

## Big Bang installation

1. Create a new git repository for the Big Bang configuration.

   You can use any git hosting e.g. GitHub, GitLab, or your own git server. For GitHub, you can create a repository using [`gh`](https://cli.github.com/manual/installation):

   ```bash
   gh repo create --private big-bang-configuration
   ```

1. Define a TypeInstance for the created git repository:

   ```bash
   export GIT_USERNAME=<your-github-username>
   # For GitHub, personal token can be generated from https://github.com/settings/tokens/new with repo permissions
   export GIT_TOKEN=<your-github-personal-token>
   # e.g. https://github.com/StructsureLabs/big-bang-configuration.git
   export GIT_REPO=<your-bigbang-conf-repo-https-url>

   cat << EOF > /tmp/git-repo.yaml
   typeInstances:
     - alias: "repository"
       typeRef:
         path: cap.type.git.repository
         revision: 0.1.0
       value:
         url: "${GIT_REPO}"
         private: true
         branchName: main # This branch cannot exists on git repository.
         username: "${GIT_USERNAME}"
         password: "${GIT_TOKEN}"
   EOF
   ```

1. Create the repository TypeInstance and export its ID:

   ```bash
   export REPO_TI_ID=$(capact ti create -f /tmp/git-repo.yaml -ojson | jq -r '.[0].id')
   ```

1. Define input TypeInstance and parameters for the Platform One Action:

   ```bash
   cat <<EOF > /tmp/bb-tis.yaml
   typeInstances:
     - name: p1-config-repo
       id: "${REPO_TI_ID}"
     - name: kubeconfig
       id: "${KUBECONFIG_TI}"
   EOF
   cat <<EOF > /tmp/bb-params.yaml
   registry1:
     username: AWS
     password: $(aws ecr get-login-password --region eu-west-1)
   bigbangValues: {}
   EOF
   ```

   You can modify the values in `/tmp/bb-params.yaml`, if needed. Under `bigbangValues` you can put any overrides for parameters that are defined in [`bigbang/values.yaml`](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/release-1.11.x/chart/values.yaml).

   > **NOTE:** We use a mirror ECR of the IronBank, so we had to provide credentials to the registry in the Action parameters. You need to change this, depending on your registry.

1. Create Action which installs Big Bang on your pre-existing Kubernetes cluster

   ```bash
   capact action create cap.interface.platform-one.big-bang.provision --name big-bang --parameters-from-file=/tmp/bb-params.yaml --type-instances-from-file=/tmp/bb-tis.yaml
   ```

1. Wait till the Action is in `READY_TO_RUN` status:

    ```bash
    watch -n 1 capact action get big-bang
    ```
    ```bash
       NAMESPACE            NAME                              PATH                         RUN       STATUS      AGE
    +--------------+--------------------+-----------------------------------------------+-------+--------------+-----+
       default        big-bang            cap.interface.platform-one.big-bang.provision   false   READY_TO_RUN   19s
    +--------------+--------------------+-----------------------------------------------+-------+--------------+-----+
    ```

    In the `STATUS` column you can see the current status of the Action. When the Action workflow is being rendered by the Engine, you will see the `BEING_RENDERED` status. After the Action finished rendering and the status is `READY_TO_RUN`, you can go to the next step.

1. Run the rendered Action:

    After the Action is in `READY_TO_RUN` status, you can run it:

    ```bash
    capact action run big-bang
    ```

1. Check the Action execution and wait till it is finished:

    ```bash
    capact action watch big-bang
    ```

1. Test that it works:

   Get the connection details to Grafana using the following command:

   ```bash
   capact action get big-bang -ojson | jq -r '.Actions[0].output.typeInstances[] | select( .typeRef.path == "cap.type.platform-one.big-bang.config" ) | .id' | xargs capact typeinstance get -ojson | jq -r '.[0].latestResourceVersion.spec.value'
   ```

   You should see a response like this, with the Grafana host, username and password:
   ```json
   {
     "grafana": {
       "host": "https://grafana.bigbang.dev",
       "password": "...",
       "username": "..."
     },
     "istioGateway": {
       "hostname": "",
       "ip": "172.24.0.2"
     }
   }
   ```

   Open Grafana in your browser and confirm it works.

   > **NOTE:** You might get a certificate issue in your browser, if you used a self-signed certificate for the BigBang ingress. In this case you have to add the certificate to your truststore.
