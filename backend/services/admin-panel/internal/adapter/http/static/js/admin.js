(function () {
  const locale = (document.documentElement.lang || "en").toLowerCase().startsWith("ru") ? "ru" : "en";
  const coordinatePairPattern = /(?:@|=|\/|,|\s)([-+]?\d{1,2}(?:\.\d+)?),\s*([-+]?\d{1,3}(?:\.\d+)?)/i;

  const validCoordinates = (lat, lon) => Number.isFinite(lat) && Number.isFinite(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  const coordinatesFromValues = (first, second, reversed = false) => {
    const firstValue = Number.parseFloat(String(first || "").trim());
    const secondValue = Number.parseFloat(String(second || "").trim());
    const lat = reversed ? secondValue : firstValue;
    const lon = reversed ? firstValue : secondValue;
    return validCoordinates(lat, lon) ? { lat, lon } : null;
  };
  const coordinatesFromDelimitedPair = (raw, reversed = false) => {
    const value = String(raw || "").trim();
    if (!value) {
      return null;
    }
    const parts = value.replace(/%2C/gi, ",").split(",");
    if (parts.length < 2) {
      return null;
    }
    return coordinatesFromValues(parts[0], parts[1], reversed);
  };
  const coordinatesFromText = (raw) => {
    let value = String(raw || "").trim();
    if (!value) {
      return null;
    }
    try {
      value = decodeURIComponent(value);
    } catch (_) {
      // Keep the original value when a copied URL contains partial escaping.
    }
    const direct = coordinatesFromDelimitedPair(value);
    if (direct) {
      return direct;
    }
    const match = value.match(coordinatePairPattern);
    if (!match) {
      return null;
    }
    return coordinatesFromValues(match[1], match[2]);
  };
  const coordinatesFromOSMFragment = (fragment) => {
    const value = String(fragment || "").trim();
    if (!value) {
      return null;
    }
    const mapPart = value.split("&").find((part) => part.startsWith("map="));
    if (!mapPart) {
      return null;
    }
    const segments = mapPart.replace(/^map=/, "").split("/");
    if (segments.length < 3) {
      return null;
    }
    return coordinatesFromValues(segments[1], segments[2]);
  };
  const mapCoordinatesFromURL = (raw) => {
    const value = String(raw || "").trim();
    if (!value) {
      return null;
    }
    let parsed = null;
    try {
      parsed = new URL(value);
    } catch (_) {
      return coordinatesFromText(value);
    }
    const query = parsed.searchParams;
    const queryPairs = [
      ["mlat", "mlon", false],
      ["lat", "lon", false],
      ["latitude", "longitude", false],
    ];
    for (const [latKey, lonKey, reversed] of queryPairs) {
      const coordinates = coordinatesFromValues(query.get(latKey), query.get(lonKey), reversed);
      if (coordinates) {
        return coordinates;
      }
    }
    for (const key of ["ll", "m"]) {
      const coordinates = coordinatesFromDelimitedPair(query.get(key), true);
      if (coordinates) {
        return coordinates;
      }
    }
    for (const key of ["q", "query", "center"]) {
      const coordinates = coordinatesFromText(query.get(key));
      if (coordinates) {
        return coordinates;
      }
    }
    return coordinatesFromOSMFragment(parsed.hash.replace(/^#/, "")) || coordinatesFromText(parsed.pathname) || coordinatesFromText(parsed.hash) || coordinatesFromText(value);
  };
  const formatCoordinate = (value) => String(Math.round(value * 10000000) / 10000000);

  document.querySelectorAll("[data-modal-open]").forEach((button) => {
    button.addEventListener("click", () => {
      const targetID = button.getAttribute("data-modal-open");
      if (!targetID) {
        return;
      }
      const target = document.getElementById(targetID);
      if (!target) {
        return;
      }
      if (typeof target.showModal === "function") {
        target.showModal();
      } else {
        target.setAttribute("open", "");
      }
    });
  });

  document.querySelectorAll("[data-modal-close]").forEach((button) => {
    button.addEventListener("click", () => {
      const dialog = button.closest("dialog");
      if (!dialog) {
        return;
      }
      if (typeof dialog.close === "function") {
        dialog.close();
      } else {
        dialog.removeAttribute("open");
      }
    });
  });

  document.querySelectorAll("dialog[data-close-on-backdrop]").forEach((dialog) => {
    dialog.addEventListener("click", (event) => {
      if (event.target !== dialog) {
        return;
      }
      dialog.close();
    });
  });

  const syncAttractionRequiredLocale = (form) => {
    const localeSelect = form.querySelector("[data-default-locale-select]");
    if (!localeSelect) {
      return;
    }
    const selectedLocale = (localeSelect.value || "ru").toLowerCase();
    form.querySelectorAll("[data-required-locale]").forEach((field) => {
      field.required = (field.getAttribute("data-required-locale") || "").toLowerCase() === selectedLocale;
    });
  };

  document.querySelectorAll("[data-attraction-form]").forEach((form) => {
    syncAttractionRequiredLocale(form);
    const localeSelect = form.querySelector("[data-default-locale-select]");
    if (localeSelect) {
      localeSelect.addEventListener("change", () => syncAttractionRequiredLocale(form));
    }
    const mapInput = form.querySelector("[data-map-url-input]");
    const latitudeInput = form.querySelector("[data-latitude-input]");
    const longitudeInput = form.querySelector("[data-longitude-input]");
    if (mapInput && latitudeInput && longitudeInput) {
      const syncMapCoordinates = (force = false) => {
        if (!force && latitudeInput.value.trim() && longitudeInput.value.trim()) {
          return;
        }
        const coordinates = mapCoordinatesFromURL(mapInput.value);
        if (!coordinates) {
          return;
        }
        latitudeInput.value = formatCoordinate(coordinates.lat);
        longitudeInput.value = formatCoordinate(coordinates.lon);
      };
      mapInput.addEventListener("input", () => syncMapCoordinates(true));
      mapInput.addEventListener("change", () => syncMapCoordinates(true));
      syncMapCoordinates();
    }
    const countrySelect = form.querySelector("[data-attraction-country-select]");
    const citySelect = form.querySelector("[data-attraction-city-select]");
    const cityLinkOptions = Array.from(form.querySelectorAll("[data-attraction-city-link-option]"));
    if (countrySelect) {
      const syncAttractionCountryFields = () => {
        const selectedCountry = (countrySelect.value || "").trim().toUpperCase();
        if (citySelect) {
          Array.from(citySelect.options).forEach((option) => {
            const optionCountry = (option.getAttribute("data-country") || "").trim().toUpperCase();
            const isBlank = option.value === "";
            const isVisible = isBlank || optionCountry === selectedCountry;
            option.hidden = !isVisible;
            option.disabled = !isVisible;
          });
          const currentOption = citySelect.selectedOptions[0];
          if (currentOption && currentOption.disabled) {
            citySelect.value = "";
          }
        }
        cityLinkOptions.forEach((option) => {
          const optionCountry = (option.getAttribute("data-country") || "").trim().toUpperCase();
          const isVisible = selectedCountry !== "" && optionCountry === selectedCountry;
          option.hidden = !isVisible;
          option.querySelectorAll("input").forEach((input) => {
            input.disabled = !isVisible;
          });
        });
      };
      countrySelect.addEventListener("change", syncAttractionCountryFields);
      syncAttractionCountryFields();
    }
  });

  document.querySelectorAll("[data-attraction-filter-form], [data-location-filter-form], [data-country-filter-form]").forEach((form) => {
    const countryInput = form.querySelector("[data-country-filter-input]");
    const countryValue = form.querySelector("[data-country-filter-value]");
    const countrySuggestions = form.querySelector("[data-country-filter-suggestions]");
    const countryOptions = Array.from(form.querySelectorAll("[data-country-filter-option]"));
    const cityGroup = form.querySelector("[data-city-filter-group]");
    const cityInput = form.querySelector("[data-city-filter-input]");
    const cityValue = form.querySelector("[data-city-filter-value]");
    const citySuggestions = form.querySelector("[data-city-filter-suggestions]");
    const cityOptions = Array.from(form.querySelectorAll("[data-city-filter-option]"));
    const hasCityFilter = Boolean(cityGroup && cityInput && cityValue && citySuggestions);
    if (!countryInput || !countryValue || !countrySuggestions) {
      return;
    }
    const normalizeSearch = (value) => {
      return (value || "")
        .trim()
        .toLocaleLowerCase()
        .normalize("NFKD")
        .replace(/[\u0300-\u036f]/g, "");
    };
    const optionValue = (option) => option.getAttribute("data-value") || "";
    const optionLabel = (option) => option.getAttribute("data-label") || option.textContent.trim();
    const optionSearch = (option) => option.getAttribute("data-search") || "";
    const matchesQuery = (option, rawQuery) => {
      const query = normalizeSearch(rawQuery);
      if (query === "") {
        return false;
      }
      const value = normalizeSearch(optionValue(option));
      const label = normalizeSearch(optionLabel(option));
      const search = normalizeSearch(optionSearch(option));
      return value.startsWith(query) || label.includes(query) || search.includes(query);
    };
    const hideSuggestions = (input, suggestions) => {
      suggestions.hidden = true;
      input.setAttribute("aria-expanded", "false");
    };
    const renderSuggestions = (input, suggestions, options, predicate) => {
      const query = input.value;
      let visibleCount = 0;
      options.forEach((option) => {
        const isVisible = (!predicate || predicate(option)) && matchesQuery(option, query);
        option.hidden = !isVisible;
        option.disabled = !isVisible;
        if (isVisible) {
          visibleCount += 1;
        }
      });
      suggestions.hidden = visibleCount === 0;
      input.setAttribute("aria-expanded", visibleCount === 0 ? "false" : "true");
    };
    const firstVisibleSuggestion = (suggestions) => {
      return Array.from(suggestions.querySelectorAll(".filter-suggestion")).find((option) => {
        return !option.hidden && !option.disabled;
      });
    };
    const focusAdjacentSuggestion = (suggestions, currentOption, direction) => {
      const visible = Array.from(suggestions.querySelectorAll(".filter-suggestion")).filter((option) => {
        return !option.hidden && !option.disabled;
      });
      if (visible.length === 0) {
        return;
      }
      const currentIndex = visible.indexOf(currentOption);
      const nextIndex = currentIndex < 0 ? 0 : (currentIndex + direction + visible.length) % visible.length;
      visible[nextIndex].focus();
    };
    const selectedCountry = () => (countryValue.value || "").trim().toUpperCase();
    const optionCountry = (option) => (option.getAttribute("data-country") || "").trim().toUpperCase();
    const cityBelongsToSelectedCountry = (option) => optionCountry(option) === selectedCountry();
    const selectedOptionMatchesInput = (options, selectedValue, input) => {
      if (!selectedValue) {
        return false;
      }
      const selected = options.find((option) => optionValue(option) === selectedValue);
      return Boolean(selected) && normalizeSearch(optionLabel(selected)) === normalizeSearch(input.value);
    };
    const setCity = (option, updateInput = true) => {
      if (!hasCityFilter) {
        return;
      }
      if (!option) {
        cityValue.value = "";
        if (updateInput) {
          cityInput.value = "";
        }
        return;
      }
      cityValue.value = optionValue(option);
      if (updateInput) {
        cityInput.value = optionLabel(option);
      }
    };
    const syncCityFilter = () => {
      if (!hasCityFilter) {
        return;
      }
      const country = selectedCountry();
      const hasCountry = country !== "";
      cityGroup.hidden = !hasCountry;
      cityInput.disabled = !hasCountry;
      cityValue.disabled = !hasCountry;
      hideSuggestions(cityInput, citySuggestions);
      cityOptions.forEach((option) => {
        option.hidden = true;
        option.disabled = !hasCountry || optionCountry(option) !== country;
      });
      const currentCity = cityOptions.find((option) => optionValue(option) === cityValue.value && cityBelongsToSelectedCountry(option));
      if (!hasCountry || (cityValue.value && !currentCity)) {
        setCity(null);
      }
    };
    const setCountry = (option, updateInput = true) => {
      const previousCountry = selectedCountry();
      if (!option) {
        countryValue.value = "";
        setCity(null);
      } else {
        countryValue.value = optionValue(option);
        if (updateInput) {
          countryInput.value = optionLabel(option);
        }
        if (previousCountry !== selectedCountry()) {
          setCity(null);
        }
      }
      syncCityFilter();
    };
    const clearCountrySelectionAfterManualInput = () => {
      if (!countryValue.value || selectedOptionMatchesInput(countryOptions, countryValue.value, countryInput)) {
        return;
      }
      setCountry(null, false);
    };
    const clearCitySelectionAfterManualInput = () => {
      if (!hasCityFilter) {
        return;
      }
      if (!cityValue.value || selectedOptionMatchesInput(cityOptions, cityValue.value, cityInput)) {
        return;
      }
      setCity(null, false);
    };
    const selectCountry = (option) => {
      setCountry(option);
      hideSuggestions(countryInput, countrySuggestions);
      countryInput.focus();
    };
    const selectCity = (option) => {
      setCity(option);
      hideSuggestions(cityInput, citySuggestions);
      cityInput.focus();
    };
    const bindSuggestionButton = (button, selectOption) => {
      button.addEventListener("mousedown", (event) => event.preventDefault());
      button.addEventListener("click", () => selectOption(button));
      button.addEventListener("keydown", (event) => {
        const suggestions = event.currentTarget.closest("[role='listbox']");
        const input = suggestions ? suggestions.previousElementSibling : null;
        if (event.key === "Escape") {
          event.preventDefault();
          if (input && suggestions) {
            hideSuggestions(input, suggestions);
            input.focus();
          }
        }
        if (event.key === "ArrowDown" || event.key === "ArrowUp") {
          event.preventDefault();
          if (suggestions) {
            focusAdjacentSuggestion(suggestions, button, event.key === "ArrowDown" ? 1 : -1);
          }
        }
      });
    };
    countryOptions.forEach((option) => bindSuggestionButton(option, selectCountry));
    if (hasCityFilter) {
      cityOptions.forEach((option) => bindSuggestionButton(option, selectCity));
    }
    countryInput.addEventListener("input", () => {
      clearCountrySelectionAfterManualInput();
      renderSuggestions(countryInput, countrySuggestions, countryOptions);
    });
    countryInput.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        hideSuggestions(countryInput, countrySuggestions);
      }
      if (event.key === "ArrowDown" && !countrySuggestions.hidden) {
        event.preventDefault();
        const first = firstVisibleSuggestion(countrySuggestions);
        if (first) {
          first.focus();
        }
      }
      if (event.key === "Enter" && !countrySuggestions.hidden) {
        const first = firstVisibleSuggestion(countrySuggestions);
        if (first) {
          event.preventDefault();
          selectCountry(first);
        }
      }
    });
    countryInput.addEventListener("blur", () => {
      if (!countryValue.value) {
        countryInput.value = "";
      }
      window.setTimeout(() => hideSuggestions(countryInput, countrySuggestions), 80);
    });
    if (hasCityFilter) {
      cityInput.addEventListener("input", () => {
        clearCitySelectionAfterManualInput();
        renderSuggestions(cityInput, citySuggestions, cityOptions, cityBelongsToSelectedCountry);
      });
      cityInput.addEventListener("keydown", (event) => {
        if (event.key === "Escape") {
          hideSuggestions(cityInput, citySuggestions);
        }
        if (event.key === "ArrowDown" && !citySuggestions.hidden) {
          event.preventDefault();
          const first = firstVisibleSuggestion(citySuggestions);
          if (first) {
            first.focus();
          }
        }
        if (event.key === "Enter" && !citySuggestions.hidden) {
          const first = firstVisibleSuggestion(citySuggestions);
          if (first) {
            event.preventDefault();
            selectCity(first);
          }
        }
      });
      cityInput.addEventListener("blur", () => {
        if (!cityValue.value) {
          cityInput.value = "";
        }
        window.setTimeout(() => hideSuggestions(cityInput, citySuggestions), 80);
      });
    }
    form.addEventListener("click", (event) => {
      if (!countryInput.contains(event.target) && !countrySuggestions.contains(event.target)) {
        hideSuggestions(countryInput, countrySuggestions);
      }
      if (hasCityFilter && !cityInput.contains(event.target) && !citySuggestions.contains(event.target)) {
        hideSuggestions(cityInput, citySuggestions);
      }
    });
    syncCityFilter();
  });

  document.querySelectorAll("[data-attraction-media-form]").forEach((form) => {
    const input = form.querySelector("[data-attraction-media-input]");
    const preview = form.querySelector("[data-attraction-media-preview]");
    const previewList = form.querySelector("[data-attraction-media-preview-list]");
    const count = form.querySelector("[data-attraction-media-count]");
    const empty = form.querySelector("[data-attraction-media-empty]");
    const manageSubmit = form.querySelector("[data-attraction-media-manage-submit]");
    const appendSubmit = form.querySelector("[data-attraction-media-append-submit]");
    const replaceSubmit = form.querySelector("[data-attraction-media-replace-submit]");
    const actionInput = form.querySelector("[data-media-action-input]");
    const currentList = form.querySelector("[data-attraction-media-current]");
    const deleteFields = form.querySelector("[data-media-delete-fields]");
    if (!input || !preview || !previewList) {
      return;
    }

    let mediaDirty = false;
    let selectedUploadFiles = Array.from(input.files || []);
    let objectURLs = [];
    const clearPreview = () => {
      objectURLs.forEach((url) => URL.revokeObjectURL(url));
      objectURLs = [];
      previewList.replaceChildren();
    };

    const maxMediaItems = 10;
    const selectedFiles = () => selectedUploadFiles;
    const syncSelectedInputFiles = () => {
      if (typeof DataTransfer !== "function") {
        return;
      }
      const transfer = new DataTransfer();
      selectedUploadFiles.forEach((file) => transfer.items.add(file));
      input.files = transfer.files;
    };
    const activeCurrentCount = () => {
      if (!currentList) {
        return 0;
      }
      return Array.from(currentList.querySelectorAll("[data-media-card]")).filter((card) => !card.classList.contains("is-deleted")).length;
    };

    const setMediaAction = (action) => {
      if (actionInput) {
        actionInput.value = action;
      }
      if (action === "append") {
        form.dataset.confirmForm = "mediaAppend";
      } else if (action === "replace") {
        form.dataset.confirmForm = "attractionMedia";
      } else {
        form.dataset.confirmForm = "mediaManage";
      }
    };

    const updateDeleteFields = () => {
      if (!deleteFields) {
        return;
      }
      deleteFields.replaceChildren();
      form.querySelectorAll("[data-media-card].is-deleted").forEach((card) => {
        const mediaID = card.getAttribute("data-media-id") || "";
        if (!mediaID) {
          return;
        }
        const field = document.createElement("input");
        field.type = "hidden";
        field.name = "delete_media_ids";
        field.value = mediaID;
        deleteFields.append(field);
      });
    };

    const syncMediaControls = () => {
      const files = selectedFiles();
      const hasFiles = files.length > 0;
      if (manageSubmit) {
        manageSubmit.disabled = !mediaDirty;
      }
      if (appendSubmit) {
        appendSubmit.disabled = !hasFiles || activeCurrentCount() + files.length > maxMediaItems;
      }
      if (replaceSubmit) {
        replaceSubmit.disabled = !hasFiles || files.length > maxMediaItems;
      }
      updateDeleteFields();
    };

    const markMediaDirty = () => {
      mediaDirty = true;
      syncMediaControls();
    };

    const updateMoveButtons = () => {
      if (!currentList) {
        return;
      }
      const cards = Array.from(currentList.querySelectorAll("[data-media-card]"));
      cards.forEach((card, index) => {
        const up = card.querySelector('[data-media-move="up"]');
        const down = card.querySelector('[data-media-move="down"]');
        if (up) {
          up.disabled = index === 0;
        }
        if (down) {
          down.disabled = index === cards.length - 1;
        }
      });
    };

    const renderPreview = () => {
      clearPreview();
      const files = selectedFiles();
      const hasFiles = files.length > 0;
      preview.hidden = !hasFiles;
      if (empty) {
        empty.hidden = hasFiles;
      }
      syncMediaControls();
      if (count) {
        const label = locale === "ru" ? "Выбрано изображений" : "Selected images";
        count.textContent = hasFiles ? `${label}: ${files.length}` : "";
      }
      files.forEach((file, index) => {
        const url = URL.createObjectURL(file);
        objectURLs.push(url);
        const figure = document.createElement("figure");
        figure.className = "media-thumb media-preview-thumb";
        figure.dataset.uploadIndex = String(index);
        const remove = document.createElement("button");
        remove.type = "button";
        remove.className = "media-remove";
        remove.dataset.uploadRemove = "true";
        remove.textContent = "x";
        remove.setAttribute("aria-label", locale === "ru" ? "Убрать из выбора" : "Remove from selection");
        const image = document.createElement("img");
        image.src = url;
        image.alt = locale === "ru" ? `Предпросмотр изображения ${index + 1}` : `Image preview ${index + 1}`;
        image.title = file.name;
        const caption = document.createElement("figcaption");
        const coverLabel = locale === "ru" ? "обложка" : "cover";
        caption.textContent = index === 0 ? `#${index + 1} · ${coverLabel}` : `#${index + 1}`;
        caption.title = file.name;
        const actions = document.createElement("div");
        actions.className = "media-card-actions";
        const up = document.createElement("button");
        up.type = "button";
        up.dataset.uploadMove = "up";
        up.textContent = locale === "ru" ? "Выше" : "Up";
        up.disabled = index === 0;
        const down = document.createElement("button");
        down.type = "button";
        down.dataset.uploadMove = "down";
        down.textContent = locale === "ru" ? "Ниже" : "Down";
        down.disabled = index === files.length - 1;
        actions.append(up, down);
        figure.append(remove, image, caption, actions);
        previewList.append(figure);
      });
    };

    previewList.addEventListener("click", (event) => {
      const target = event.target instanceof Element ? event.target : null;
      if (!target) {
        return;
      }
      const figure = target.closest("[data-upload-index]");
      if (!figure) {
        return;
      }
      const index = Number.parseInt(figure.getAttribute("data-upload-index") || "", 10);
      if (!Number.isFinite(index) || index < 0 || index >= selectedUploadFiles.length) {
        return;
      }
      if (target.closest("[data-upload-remove]")) {
        selectedUploadFiles.splice(index, 1);
        syncSelectedInputFiles();
        renderPreview();
        return;
      }
      const moveButton = target.closest("[data-upload-move]");
      if (!moveButton) {
        return;
      }
      const direction = moveButton.getAttribute("data-upload-move");
      if (direction === "up" && index > 0) {
        [selectedUploadFiles[index - 1], selectedUploadFiles[index]] = [selectedUploadFiles[index], selectedUploadFiles[index - 1]];
      } else if (direction === "down" && index < selectedUploadFiles.length - 1) {
        [selectedUploadFiles[index + 1], selectedUploadFiles[index]] = [selectedUploadFiles[index], selectedUploadFiles[index + 1]];
      }
      syncSelectedInputFiles();
      renderPreview();
    });

    form.querySelectorAll("[data-media-action]").forEach((button) => {
      button.addEventListener("click", () => {
        setMediaAction(button.getAttribute("data-media-action") || "manage");
      });
    });

    if (currentList) {
      currentList.addEventListener("click", (event) => {
        const target = event.target instanceof Element ? event.target : null;
        if (!target) {
          return;
        }
        const moveButton = target.closest("[data-media-move]");
        if (moveButton) {
          const card = moveButton.closest("[data-media-card]");
          if (!card) {
            return;
          }
          const direction = moveButton.getAttribute("data-media-move");
          if (direction === "up" && card.previousElementSibling) {
            currentList.insertBefore(card, card.previousElementSibling);
            markMediaDirty();
            updateMoveButtons();
          } else if (direction === "down" && card.nextElementSibling) {
            currentList.insertBefore(card.nextElementSibling, card);
            markMediaDirty();
            updateMoveButtons();
          }
          return;
        }
        const deleteButton = target.closest("[data-media-delete]");
        if (deleteButton) {
          const card = deleteButton.closest("[data-media-card]");
          if (!card) {
            return;
          }
          const isDeleted = card.classList.toggle("is-deleted");
          const note = card.querySelector("[data-media-delete-note]");
          if (note) {
            note.hidden = !isDeleted;
          }
          deleteButton.textContent = isDeleted ? "undo" : "x";
          deleteButton.setAttribute("aria-label", isDeleted ? (locale === "ru" ? "Восстановить изображение" : "Restore image") : (locale === "ru" ? "Удалить изображение" : "Delete image"));
          markMediaDirty();
        }
      });
    }

    input.addEventListener("change", () => {
      selectedUploadFiles = Array.from(input.files || []);
      renderPreview();
    });
    form.addEventListener("reset", () => {
      mediaDirty = false;
      selectedUploadFiles = [];
      window.setTimeout(renderPreview, 0);
    });
    window.addEventListener("beforeunload", clearPreview);
    updateMoveButtons();
    renderPreview();
  });

  document.querySelectorAll("form").forEach((form) => {
    form.addEventListener("submit", (event) => {
      syncAttractionRequiredLocale(form);
      form.classList.add("was-validated");
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopImmediatePropagation();
      }
    });
  });

  const dialog = document.getElementById("decision-confirmation-dialog");
  if (!dialog) {
    return;
  }

  const message = dialog.querySelector("[data-confirm-message]");
  const submitButton = dialog.querySelector("[data-confirm-submit]");
  const cancelButton = dialog.querySelector("[data-confirm-cancel]");
  let pendingForm = null;
  let pendingSubmitter = null;

  const labels = {
    approve: {
      en: "This will approve and publish the excursion. Continue?",
      ru: "Экскурсия будет одобрена и опубликована. Продолжить?",
    },
    reject: {
      en: "This will reject the excursion and hide it from publication. Continue?",
      ru: "Экскурсия будет отклонена и скрыта от публикации. Продолжить?",
    },
    attractionMedia: {
      en: "Selected images will replace the current attraction carousel in this exact order. Continue?",
      ru: "Выбранные изображения заменят текущую карусель достопримечательности именно в этом порядке. Продолжить?",
    },
    mediaAppend: {
      en: "Selected images will be added to the end of the current carousel. Continue?",
      ru: "Выбранные изображения будут добавлены в конец текущей карусели. Продолжить?",
    },
    mediaManage: {
      en: "The current carousel order and deletions will be saved. Continue?",
      ru: "Порядок текущей карусели и выбранные удаления будут сохранены. Продолжить?",
    },
    revoke: {
      en: "This will revoke guide status, disable guide tools, and hide public offers. Continue?",
      ru: "Статус гида будет отозван, функции гида отключены, публичные предложения скрыты. Продолжить?",
    },
  };

  document.querySelectorAll("[data-confirm-form]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      if (event.defaultPrevented || !form.checkValidity()) {
        return;
      }
      if (form.dataset.confirmed === "true") {
        return;
      }
      event.preventDefault();
      pendingForm = form;
      pendingSubmitter = event.submitter || null;
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
        pendingForm.requestSubmit(pendingSubmitter || undefined);
      } else {
        pendingForm.submit();
      }
    });
  }

  if (cancelButton) {
    cancelButton.addEventListener("click", () => {
      pendingForm = null;
      pendingSubmitter = null;
      dialog.close();
    });
  }
})();
