function makeCopyButton(getText, label, extraClass) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "copy-code-button" + (extraClass ? " " + extraClass : "");
  button.textContent = "copy";
  button.setAttribute("aria-label", label);

  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(getText());
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

  return button;
}

document.querySelectorAll("pre.giallo").forEach((pre) => {
  const code = pre.querySelector("code");
  if (!code) return;

  const codeCopyButton = makeCopyButton(() => code.innerText, "Copy code to clipboard");

  const name = code.getAttribute("data-name");
  if (!name) {
    pre.appendChild(codeCopyButton);
    return;
  }

  const label = document.createElement("div");
  label.className = "code-label";

  const filename = document.createElement("span");
  filename.className = "code-filename";
  filename.textContent = name;
  label.appendChild(filename);
  label.appendChild(makeCopyButton(() => name, "Copy filename to clipboard", "copy-name-button inline"));

  codeCopyButton.classList.add("inline", "copy-code-button-right");
  label.appendChild(codeCopyButton);

  pre.insertBefore(label, code);
});
