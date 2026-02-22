interface ToastMessage {
  id: number;
  message: string;
  type: "success" | "error";
}

let toastId = 0;
const listeners: Set<(msg: ToastMessage) => void> = new Set();

export function showToast(
  message: string,
  type: "success" | "error" = "success",
) {
  const msg: ToastMessage = { id: ++toastId, message, type };
  listeners.forEach((fn) => fn(msg));
}

export function addToastListener(fn: (msg: ToastMessage) => void) {
  listeners.add(fn);
  return () => {
    listeners.delete(fn);
  };
}

export type { ToastMessage };
