import { useEffect, useState, useCallback } from "react";
import { CheckCircle, AlertCircle } from "lucide-react";
import { addToastListener, type ToastMessage } from "../utils/toast";

export function Toast() {
  const [messages, setMessages] = useState<ToastMessage[]>([]);

  const addMessage = useCallback((msg: ToastMessage) => {
    setMessages((prev) => [...prev, msg]);
    setTimeout(() => {
      setMessages((prev) => prev.filter((m) => m.id !== msg.id));
    }, 3000);
  }, []);

  useEffect(() => {
    return addToastListener(addMessage);
  }, [addMessage]);

  if (messages.length === 0) return null;

  return (
    <div className="toast toast-end toast-bottom z-50">
      {messages.map((msg) => (
        <div
          key={msg.id}
          className={`alert ${msg.type === "success" ? "alert-success" : "alert-error"} shadow-lg`}
        >
          {msg.type === "success" ? (
            <CheckCircle className="w-5 h-5" />
          ) : (
            <AlertCircle className="w-5 h-5" />
          )}
          <span>{msg.message}</span>
        </div>
      ))}
    </div>
  );
}
