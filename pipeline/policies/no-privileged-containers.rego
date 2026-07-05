
package kubernetes.admission

# Deny any pod that requests privileged container mode.
# Maps to: RBI Section 5.1 (vulnerability assessment) and PCI-DSS 6.4 (secure configuration)

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Privileged container not allowed: %v", [container.name])
}
