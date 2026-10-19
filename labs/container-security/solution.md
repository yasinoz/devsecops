# Lab Solution

Here's my solution:

- [lab/deployment.yaml](./lab/deployment.yaml)

On my Docker Desktop cluster all the controls can be applied :) 

The app listens on port 80 by default, so dropping all capabilities might be an issue on some clusters. My update also switches to a different port, 5000.

Take this approach with your own apps to be sure you don't break them by applying blanket security controls.

___
> Back to the [exercises](README.md).
