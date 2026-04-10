# Nginx Pod with ConfigMap Volume

In this scenario you will learn how to serve custom content from an nginx container without rebuilding the image.

Instead of baking HTML into the image, you will store it in a **ConfigMap** and mount it into the Pod as a volume. This is a common pattern for injecting configuration or content into containers at runtime.

## What you will do

1. Create a ConfigMap that holds a custom `index.html`
2. Create a Pod that mounts the ConfigMap at nginx's web root
3. Verify that nginx serves your custom page
