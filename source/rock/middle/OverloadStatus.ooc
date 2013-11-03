/**
 * The status of the resolution of an operator overload.
 * Used by UnaryOp and BinaryOp
 */
OverloadStatus: enum {
	WAITING   /* We could have an overload but something is not resolved fully so we are waiting for it to do so. */
	REPLACED  /* We have found an overload and have replaced the operator object with a function call. */
	NONE      /* There is no overload. */
}