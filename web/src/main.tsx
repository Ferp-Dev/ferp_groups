import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { isEnvBrowser } from "./utils/misc";

const root = ReactDOM.createRoot(document.getElementById("root")!);
const renderApp = () => {
    root.render(
        <React.StrictMode>
            <App />
        </React.StrictMode>
    );
};

if (isEnvBrowser()) {
    renderApp();
} else {
    window.addEventListener("message", (event) => {
        if (event.data !== "parentReady") return;

        renderApp();
    });
}
