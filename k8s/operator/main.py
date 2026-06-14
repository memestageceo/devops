import kopf
import kubernetes
import os
import yaml

# import logging
from typing import Any


# @kopf.on.create("ephemeralvolumeclaims")
# def create_fn(body: kopf.Body, **_: Any) -> None:
#     logging.info(f"A handler is called with body: {body}")


@kopf.on.create("ephemeralvolumeclaims")
def create_fn(
    spec: kopf.Spec, name: str, namespace: str | None, logger: kopf.Logger, **_: Any
) -> dict[str, str]:
    size = spec.get("size")
    if not size:
        raise kopf.PermanentError(f"Size must be set. Got {size!r}.")

    path = os.path.join(os.path.dirname(__file__), "pvc.yaml")
    tmpl = open(path, "rt").read()
    text = tmpl.format(name=name, size=size)
    data = yaml.safe_load(text)

    # mark PVC as chlid of EVC
    kopf.adopt(data)

    api = kubernetes.client.CoreV1Api()
    obj = api.create_namespaced_persistent_volume_claim(
        namespace=namespace,
        body=data,
    )

    logger.info(f"PVC child is created: {obj}")

    return {"pvc-name": obj.metadata.name}


# UPDATE -------------------


@kopf.on.update("ephemeralvolumeclaims")
def update_fn(
    spec: kopf.Spec,
    status: kopf.Status,
    namespace: str | None,
    logger: kopf.Logger,
    **_: Any,
) -> None:
    size = spec.get("size", None)
    if not size:
        raise kopf.PermanentError(f"Size must be set. Got {size!r}.")

    pvc_name = status["create_fn"]["pvc-name"]
    pvc_patch = {"spec": {"resources": {"requests": {"storage": size}}}}

    api = kubernetes.client.CoreV1Api()
    obj = api.patch_namespaced_persistent_volume_claim(
        namespace=namespace,
        name=pvc_name,
        body=pvc_patch,
    )

    logger.info(f"PVC child is updated: {obj}")


def main():
    print("Hello from operator!")


# if __name__ == "__main__":
#     main()
