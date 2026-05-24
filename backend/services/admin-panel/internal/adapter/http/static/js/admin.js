(function () {
  const dialog = document.getElementById("decision-confirmation-dialog");
  if (!dialog) {
    return;
  }

  const message = dialog.querySelector("[data-confirm-message]");
  const submitButton = dialog.querySelector("[data-confirm-submit]");
  const cancelButton = dialog.querySelector("[data-confirm-cancel]");
  let pendingForm = null;

  const labels = {
    approve: {
      en: "This will approve and publish the excursion. Continue?",
      ru: "Экскурсия будет одобрена и опубликована. Продолжить?",
    },
    reject: {
      en: "This will reject the excursion and hide it from publication. Continue?",
      ru: "Экскурсия будет отклонена и скрыта от публикации. Продолжить?",
    },
  };

  const locale = (document.documentElement.lang || "en").toLowerCase().startsWith("ru") ? "ru" : "en";

  document.querySelectorAll("[data-confirm-form]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      if (form.dataset.confirmed === "true") {
        return;
      }
      event.preventDefault();
      pendingForm = form;
      const type = form.dataset.confirmForm || "approve";
      if (message) {
        message.textContent = (labels[type] && labels[type][locale]) || labels.approve[locale];
      }
      if (typeof dialog.showModal === "function") {
        dialog.showModal();
      } else if (window.confirm(message ? message.textContent : "")) {
        form.dataset.confirmed = "true";
        if (typeof form.requestSubmit === "function") {
          form.requestSubmit();
        } else {
          form.submit();
        }
      }
    });
  });

  if (submitButton) {
    submitButton.addEventListener("click", () => {
      if (!pendingForm) {
        dialog.close();
        return;
      }
      pendingForm.dataset.confirmed = "true";
      dialog.close();
      if (typeof pendingForm.requestSubmit === "function") {
        pendingForm.requestSubmit();
      } else {
        pendingForm.submit();
      }
    });
  }

  if (cancelButton) {
    cancelButton.addEventListener("click", () => {
      pendingForm = null;
      dialog.close();
    });
  }
})();
