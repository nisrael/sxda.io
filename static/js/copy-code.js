document.querySelectorAll("pre.giallo").forEach((pre) => {
  const code = pre.querySelector("code");
  if (!code) return;

  const button = document.createElement("button");
  button.type = "button";
  button.className = "copy-code-button";
  button.textContent = "copy";
  button.setAttribute("aria-label", "Copy code to clipboard");

  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(code.innerText);
      button.textContent = "copied";
      button.classList.add("copied");
    } catch {
      button.textContent = "failed";
    }
    setTimeout(() => {
      button.textContent = "copy";
      button.classList.remove("copied");
    }, 1500);
  });

  pre.appendChild(button);
});
