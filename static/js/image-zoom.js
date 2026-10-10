const dialog = document.createElement("dialog");
dialog.className = "image-zoom";
const zoomed = document.createElement("img");
dialog.appendChild(zoomed);
document.body.appendChild(dialog);

dialog.addEventListener("click", () => dialog.close());

document.querySelectorAll(".post-body img").forEach((img) => {
  img.classList.add("zoomable");
  img.addEventListener("click", () => {
    zoomed.src = img.src;
    zoomed.alt = img.alt;
    dialog.showModal();
    dialog.scrollTop = 0;
  });
});
