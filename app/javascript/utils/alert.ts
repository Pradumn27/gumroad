const ALERT_KEY = "alert";

export const showAlert = (
  message: string,
  status: "success" | "error" | "info" | "warning",
  options: { html?: boolean } = { html: false },
) => {
  window.postMessage(
    {
      type: ALERT_KEY,
      payload: { message, status: status === "error" ? "danger" : status, html: options.html },
    },
    window.location.origin,
  );
};
