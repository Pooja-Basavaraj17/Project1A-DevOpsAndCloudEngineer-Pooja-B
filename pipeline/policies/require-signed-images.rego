package kubernetes.admission

# Reject any container image that has not been signed via Cosign.
# Maps to: RBI Section 7.2 (third-party risk) and supply chain provenance requirements.
# In practice, image signature verification happens via the Cosign/Kyverno image
# verification policy at admission time - this Rego policy represents the logical
# check enforced by that integration.

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not startswith(container.image, "registry.novapay.internal/")
    msg := sprintf("Image must be pulled from approved signed registry: %v", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Image tag 'latest' is not allowed in production: %v", [container.name])
}
