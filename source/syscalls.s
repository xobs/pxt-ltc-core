.cpu    cortex-m0plus
.fpu    softvfp
.text
.thumb
.align  2

.global memset
memset:
    svc #5

.global malloc
malloc:
    svc #85
