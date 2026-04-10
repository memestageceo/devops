# Well done!

You have successfully:

- Created a **ConfigMap** to store custom HTML content
- Mounted the ConfigMap as a **volume** inside an nginx Pod
- Verified that nginx serves the content defined in the ConfigMap

## Key takeaways

- ConfigMaps decouple configuration from container images.
- Mounting a ConfigMap as a volume exposes each key as a file inside the container.
- Updating the ConfigMap will eventually reflect inside the running Pod without a rebuild.
