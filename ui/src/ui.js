const ui = (() => {
  const pendingApps = [];
  let autoMountScheduled = false;

  // Helper to wrap builders with Proxy for better error messages
  function wrapBuilder(instance, className, chainHistory = []) {
    const methods = Object.getOwnPropertyNames(Object.getPrototypeOf(instance))
      .filter(m => m !== 'constructor' && typeof instance[m] === 'function');

    return new Proxy(instance, {
      get(target, prop) {
        // Track chain for error messages
        target._chainHistory = chainHistory;

        if (prop in target) {
          const value = target[prop];
          if (typeof value === 'function') {
            return function(...args) {
              const result = value.apply(target, args);
              // If result is a builder object, wrap it too
              if (result && typeof result === 'object' && result.constructor &&
                  result.constructor.name.includes('Builder')) {
                // Format arguments nicely for the chain
                const formatArg = (a) => {
                  if (typeof a === 'string') {
                    const short = a.length > 20 ? a.slice(0, 20) + '...' : a;
                    return `"${short.replace(/\n/g, ' ')}"`;
                  }
                  if (Array.isArray(a)) return `[${a.length} items]`;
                  if (typeof a === 'object' && a !== null) return '{...}';
                  return String(a);
                };
                const argStr = args.length > 0 ? `(${args.map(formatArg).join(', ')})` : '()';
                const newChain = [...chainHistory, `.${prop}${argStr}`];
                return wrapBuilder(result, result.constructor.name, newChain);
              }
              return result;
            };
          }
          return value;
        }

        // Property doesn't exist - provide helpful error
        if (typeof prop === 'string' && !prop.startsWith('_')) {
          const suggestion = methods.find(m => m.toLowerCase().includes(prop.toLowerCase()));

          // Format chain nicely - show last 5 calls max
          const recentChain = chainHistory.slice(-5);
          const chainStr = recentChain.length > 0
            ? (chainHistory.length > 5 ? '  ...\n' : '') + recentChain.map(c => `  ${c}`).join('\n')
            : '  (start of chain)';

          let errorMsg = `\n[ui.js] ❌ ${className} has no method "${prop}"\n\n`;
          errorMsg += `Available methods:\n  ${methods.join(', ')}\n\n`;
          errorMsg += `Chain (last ${Math.min(chainHistory.length, 5)} calls):\n${chainStr}\n  .${prop}() ← ERROR HERE\n`;
          if (suggestion) {
            errorMsg += `\n💡 Did you mean: "${suggestion}"?\n`;
          }
          console.error(errorMsg);

          // Return a function that throws to give a cleaner stack trace
          return function() {
            throw new Error(`[ui.js] ${className}.${prop} is not a function. See console for available methods.`);
          };
        }
        return undefined;
      }
    });
  }

  function app(title) {
    const builder = new AppBuilder(title);
    pendingApps.push(builder);
    scheduleAutoMount();
    return wrapBuilder(builder, 'AppBuilder', [`ui.app("${title || 'App'}")`]);
  }

  class AppBuilder {
    constructor(title) {
      this.title = title || 'App';
      this.blurbText = '';
      this.sections = [];
      this.groups = [];
      this.store = {};
      this.refreshAll = null;
      this.mounted = false;
    }
    blurb(text) {
      this.blurbText = text || '';
      return this;
    }
    group(title) {
      const group = new GroupBuilder(this, title);
      this.groups.push(group);
      return group;
    }
    section(title) {
      const section = new SectionBuilder(this, title, null);
      this.sections.push(section);
      return section;
    }
    mount(targetId) {
      if (this.mounted) return;
      renderApp(this, targetId || 'app');
      this.mounted = true;
    }
  }

  class GroupBuilder {
    constructor(app, title) {
      this.app = app;
      this.title = title || '';
      this.blurbText = '';
      this.sections = [];
      this.layoutConfig = null;
    }
    blurb(text) {
      this.blurbText = text || '';
      return this;
    }
    grid(cols) {
      // Signature: layout container for side-by-side sections.
      this.layoutConfig = { type: 'grid', cols: cols || 2 };
      return this;
    }
    sticky(options) {
      // Signature: sticky container (sidebars).
      this.layoutConfig = Object.assign({}, this.layoutConfig, { sticky: true, stickyOptions: options || {} });
      return this;
    }
    section(title) {
      const section = new SectionBuilder(this.app, title, this);
      this.sections.push(section);
      return section;
    }
    end() {
      return this.app;
    }
  }

  function mount(builder, targetId) {
    if (!builder || typeof builder.mount !== 'function') return;
    builder.mount(targetId || 'app');
  }

  class SectionBuilder {
    constructor(app, title, parent) {
      this.app = app;
      this.parent = parent || null;
      this.title = title || 'Section';
      this.sectionId = slugify(this.title);
      this.readConfig = null;
      this.listTemplate = '';
      this.actions = [];
      this.rowFields = [];
      this.rowActions = [];
      this.appStore = app.store;
      this.storeViewConfig = null;
      this.sectionFields = [];
      this.queryMap = null;
      this.metaConfig = null;
      this.storeMap = {};
      this.wsConfig = null;
      this.linksList = [];
      this.kpiConfig = null;
      this.jsonConfig = null;
      this.textConfig = null;
      this.markdownConfig = null;
      this.htmlContent = null;
      this.customRenderer = null;
      this.renderHook = null;
      this.autoConfig = null;
      this.mockConfig = null;
      this.suppressOutput = false;
      this.noAutoRefresh = false;
      this.layoutConfig = null;
      this.templateMode = null;
    }
    id(value) {
      this.sectionId = value;
      return this;
    }
    mock(generator) {
      // Signature: Smart Mocking System - show placeholder data when backend is offline.
      this.mockConfig = generator;
      return this;
    }
    onRender(callback) {
      // Signature: Lifecycle hook for custom library initialization (Charts, Maps).
      this.renderHook = callback;
      return this;
    }
    read(path) {
      if (typeof path === 'string') {
        this.readConfig = { method: 'GET', path };
      } else {
        this.readConfig = path;
      }
      return this;
    }
    query(map) {
      // Signature: chapter-4/4-4-pagination, example-02-http-basics.
      this.queryMap = map || {};
      return this;
    }
    list(template) {
      this.listTemplate = template || '';
      return this;
    }
    template(name) {
      // Signature: chapter-9 geo-search, live-poll (table display mode).
      this.templateMode = name || 'default';
      return this;
    }
    listFrom(path) {
      // Signature: chapter-4/4-4-pagination (items list from query results).
      this.listFromPath = path;
      return this;
    }
    meta(template, path) {
      // Signature: chapter-4/4-4-pagination.
      this.metaConfig = { template, path };
      return this;
    }
    fields(config) {
      this.sectionFields = normalizeFields(config);
      return this;
    }
    links(list) {
      // Signature: chapter-5/5-7-exports download links.
      this.linksList = list || [];
      return this;
    }
    store(map) {
      // Signature: chapter-4/4-4-pagination (store query results).
      this.storeMap = Object.assign({}, this.storeMap, map);
      return this;
    }
    hidden() {
      // Signature: hide section output (useful for store-only reads).
      this.suppressOutput = true;
      return this;
    }
    storeView(key, template) {
      // Signature: chapter-3 JWT/CSRF token display.
      this.storeViewConfig = { key, template: template || `{{${key}}}` };
      return this;
    }
    kpis(items, path) {
      // Signature: chapter-4/4-6-caching, chapter-6/6-1-sql-basics.
      this.kpiConfig = { items: items || [], path };
      return this;
    }
    jsonView(path) {
      // Signature: chapter-4/4-7-observability.
      this.jsonConfig = { path };
      return this;
    }
    textBlock(text, path) {
      // Signature: chapter-0 UI language docs.
      this.textConfig = { text: text || '', path };
      return this;
    }
    html(content) {
      // Signature: static HTML content block.
      this.htmlContent = content || '';
      return this;
    }
    markdown(text, path) {
      // Signature: chapter-4/4-1-validation, chapter-0 UI language docs.
      this.markdownConfig = { text: text || '', path };
      return this;
    }
    customView(renderer) {
      // Signature: custom render escape hatch (manual UI extensions).
      this.customRenderer = renderer;
      return this;
    }
    auto(path) {
      // Signature: chapter-0 UI language docs (opinionated view).
      this.autoConfig = { path };
      return this;
    }
    noOutput() {
      // Signature: chapter-4/4-7-observability (hide raw action output).
      this.suppressOutput = true;
      return this;
    }
    noRefresh() {
      // Signature: opt-out of default refresh when section has read().
      this.noAutoRefresh = true;
      return this;
    }
    grid(cols, gap) {
      // Signature: layout helper for side-by-side sections.
      this.layoutConfig = { type: 'grid', cols: cols || 2, gap: gap || 6 };
      return this;
    }
    sticky(options) {
      // Signature: layout helper for sticky sections.
      this.layoutConfig = Object.assign({}, this.layoutConfig, { sticky: true, stickyOptions: options || {} });
      return this;
    }
    websocket(config) {
      // Signature: chapter-5 websocket demos (server + client).
      this.wsConfig = config || {};
      return this;
    }
    action(label) {
      const action = new ActionBuilder(this, label, false);
      this.actions.push(action);
      return action;
    }
    rowField(key, config) {
      // Signature: chapter-1/6 envelope row actions, chapter-6 workflow actions.
      this.rowFields.push(normalizeField(key, config));
      return this;
    }
    rowAction(label) {
      // Signature: chapter-1/6 allocate/spend, chapter-6 workflow buttons.
      const action = new ActionBuilder(this, label, true);
      this.rowActions.push(action);
      return action;
    }
    end() {
      return this.parent || this.app;
    }
  }

  class ActionBuilder {
    constructor(section, label, isRow) {
      this.section = section;
      this.label = label || 'Action';
      this.isRow = isRow;
      this.method = 'POST';
      this.path = '';
      this.fieldList = [];
      this.withCreds = false;
      this.headerMap = {};
      this.storeMap = {};
      this.authMode = null;
      this.localOnly = false;
      this.adjustments = [];
      this.setMap = {};
      this.refreshAllFlag = false;
      this.bodyMap = {};
      this.headerStoreMap = {};
      this.customHandler = null;
    }
    get(path) {
      this.method = 'GET';
      this.path = path;
      return this;
    }
    post(path) {
      this.method = 'POST';
      this.path = path;
      return this;
    }
    put(path) {
      // Signature: example-02-http-basics update by name.
      this.method = 'PUT';
      this.path = path;
      return this;
    }
    del(path) {
      // Signature: example-02-http-basics delete by name.
      this.method = 'DELETE';
      this.path = path;
      return this;
    }
    delete(path) {
      // Alias for del() - more intuitive name.
      return this.del(path);
    }
    confirm(message) {
      // Signature: show confirmation dialog before action.
      this.confirmMessage = message || 'Are you sure?';
      return this;
    }
    upload(path) {
      // Signature: chapter-4/4-8-uploads.
      this.method = 'UPLOAD';
      this.path = path;
      return this;
    }
    local() {
      // Signature: chapter-4/4-4-pagination prev/next controls.
      this.localOnly = true;
      return this;
    }
    refreshAll() {
      // Signature: chapter-4/4-4-pagination query triggers results refresh.
      this.refreshAllFlag = true;
      return this;
    }
    field(key, value, type) {
      this.fieldList.push(normalizeField(key, { value, type }));
      return this;
    }
    fields(config) {
      Object.entries(config || {}).forEach(([key, value]) => {
        this.fieldList.push(normalizeField(key, value));
      });
      return this;
    }
    body(map) {
      // Signature: chapter-4/4-3-transactions transfer payload.
      this.bodyMap = Object.assign({}, this.bodyMap, map);
      return this;
    }
    set(map) {
      this.setMap = Object.assign({}, this.setMap, map);
      return this;
    }
    adjust(key, delta, minValue) {
      this.adjustments.push({ key, delta, minValue });
      return this;
    }
    creds() {
      // Signature: chapter-3 cookie/jwt/auth flows.
      this.withCreds = true;
      return this;
    }
    headers(map) {
      // Signature: chapter-3 CSRF, chapter-4/4-2-idempotency.
      this.headerMap = Object.assign({}, this.headerMap, map);
      return this;
    }
    store(map) {
      // Signature: chapter-3 JWT/CSRF token capture.
      this.storeMap = Object.assign({}, this.storeMap, map);
      return this;
    }
    headersFrom(map) {
      // Signature: chapter-4/4-7-observability.
      this.headerStoreMap = Object.assign({}, this.headerStoreMap, map);
      return this;
    }
    custom(handler) {
      // Signature: chapter-5/5-4-webhooks signing flow.
      this.customHandler = handler;
      return this;
    }
    basic(userKey, passKey) {
      // Signature: chapter-3 basic auth.
      this.authMode = { type: 'basic', userKey, passKey };
      return this;
    }
    bearer(tokenKey) {
      // Signature: chapter-3 API key + JWT.
      this.authMode = { type: 'bearer', tokenKey };
      return this;
    }
    end() {
      return this.section;
    }
  }

  function renderApp(app, targetId) {
    const root = ensureRoot(targetId);
    root.innerHTML = '';

    const container = document.createElement('div');
    container.className = 'mx-auto max-w-4xl px-6 py-10 pb-24 space-y-6';
    const header = document.createElement('header');
    header.className = 'space-y-2';
    const title = document.createElement('h1');
    title.className = 'text-2xl font-semibold';
    title.textContent = app.title;
    header.appendChild(title);
    if (app.blurbText) {
      const blurb = document.createElement('p');
      blurb.className = 'text-slate-600';
      blurb.textContent = app.blurbText;
      header.appendChild(blurb);
    }
    container.appendChild(header);

    const sectionEls = [];

    const renderSectionList = (sections, target, layout) => {
      let wrap = target;
      if (layout && layout.type === 'grid') {
        wrap = document.createElement('div');
        const cols = Math.max(1, layout.cols || 2);
        wrap.className = 'grid';
        wrap.style.gap = `${layout.gap || 6}px`;
        wrap.style.gridTemplateColumns = `repeat(${cols}, minmax(0, 1fr))`;
        target.appendChild(wrap);
      }
      sections.forEach((section) => {
        const el = renderSection(section);
        sectionEls.push(el);
        wrap.appendChild(el.root);
      });
    };

    if (app.groups.length > 0) {
      app.groups.forEach((group) => {
        const groupWrap = document.createElement('div');
        groupWrap.className = 'space-y-4';
        if (group.title) {
          const gTitle = document.createElement('h2');
          gTitle.className = 'text-lg font-semibold text-slate-800';
          gTitle.textContent = group.title;
          groupWrap.appendChild(gTitle);
        }
        if (group.blurbText) {
          const gBlurb = document.createElement('p');
          gBlurb.className = 'text-sm text-slate-600';
          gBlurb.textContent = group.blurbText;
          groupWrap.appendChild(gBlurb);
        }
        if (group.layoutConfig && group.layoutConfig.sticky) {
          groupWrap.style.position = 'sticky';
          const opts = group.layoutConfig.stickyOptions || {};
          groupWrap.style.top = opts.top !== undefined ? (typeof opts.top === 'number' ? `${opts.top}px` : opts.top) : '16px';
          if (opts.maxHeight !== undefined) groupWrap.style.maxHeight = typeof opts.maxHeight === 'number' ? `${opts.maxHeight}px` : opts.maxHeight;
          if (opts.width !== undefined) groupWrap.style.width = typeof opts.width === 'number' ? `${opts.width}px` : opts.width;
        }
        renderSectionList(group.sections, groupWrap, group.layoutConfig);
        container.appendChild(groupWrap);
      });
    } else {
      renderSectionList(app.sections, container, null);
    }

    root.appendChild(container);
    root.appendChild(renderFooter());

    const refreshAll = async () => {
      for (const el of sectionEls) {
        await el.refresh();
      }
    };
    app.refreshAll = refreshAll;

    refreshAll();
  }

  function renderSection(section) {
    if (section.wsConfig) {
      return renderWebSocketSection(section);
    }
    const root = document.createElement('section');
    const classes = ['rounded-xl', 'border', 'border-slate-200', 'bg-white', 'p-6', 'shadow-sm', 'space-y-4'];
    if (section.layoutConfig && section.layoutConfig.sticky) {
      classes.push('sticky');
    }
    root.className = classes.join(' ');
    if (section.layoutConfig && section.layoutConfig.stickyOptions) {
      const opts = section.layoutConfig.stickyOptions;
      if (opts.top !== undefined) root.style.top = typeof opts.top === 'number' ? `${opts.top}px` : opts.top;
      if (opts.maxHeight !== undefined) root.style.maxHeight = typeof opts.maxHeight === 'number' ? `${opts.maxHeight}px` : opts.maxHeight;
      if (opts.height !== undefined) root.style.height = typeof opts.height === 'number' ? `${opts.height}px` : opts.height;
      if (opts.width !== undefined) root.style.width = typeof opts.width === 'number' ? `${opts.width}px` : opts.width;
      root.style.position = 'sticky';
    }

    const title = document.createElement('h2');
    title.className = 'text-lg font-semibold';
    title.textContent = section.title;
    root.appendChild(title);

    const actionWrap = document.createElement('div');
    actionWrap.className = 'space-y-3';

    let output = null;
    if (!section.suppressOutput) {
      output = document.createElement('pre');
      output.className = 'rounded bg-slate-100 p-3 text-xs text-slate-700';
      output.textContent = '-';
    }

    if (section.linksList && section.linksList.length > 0) {
      const linkRow = document.createElement('div');
      linkRow.className = 'flex flex-wrap gap-2';
      section.linksList.forEach((link) => {
        const a = document.createElement('a');
        a.className = 'rounded border border-slate-300 px-4 py-2 text-sm';
        a.href = link.href;
        a.textContent = link.label;
        if (link.target) a.target = link.target;
        linkRow.appendChild(a);
      });
      root.appendChild(linkRow);
    }

    const sectionInputs = {};
    const selectBindings = [];
    if (section.sectionFields && section.sectionFields.length > 0) {
      const fieldRow = document.createElement('div');
      fieldRow.className = 'grid gap-2 sm:grid-cols-4';
      section.sectionFields.forEach((field) => {
        const input = renderField(field, section.appStore);
        sectionInputs[field.key] = input;
        if (field.optionsFrom) {
          selectBindings.push({ field, input });
        }
        fieldRow.appendChild(input);
      });
      root.appendChild(fieldRow);
    }

    if (section.actions.length > 0) {
      section.actions.forEach((action) => {
        actionWrap.appendChild(renderActionForm(action, output, section.appStore, sectionInputs, section, selectBindings));
      });
      root.appendChild(actionWrap);
    }

    let metaEl = null;
    if (section.metaConfig) {
      metaEl = document.createElement('div');
      metaEl.className = 'text-sm text-slate-500';
      metaEl.textContent = '-';
      root.appendChild(metaEl);
    }

    const listWrap = document.createElement('div');
    listWrap.className = 'space-y-2';
    root.appendChild(listWrap);

    let kpiWrap = null;
    if (section.kpiConfig) {
      kpiWrap = document.createElement('div');
      kpiWrap.className = 'grid gap-3 sm:grid-cols-3';
      root.appendChild(kpiWrap);
    }

    let jsonWrap = null;
    if (section.jsonConfig) {
      jsonWrap = document.createElement('pre');
      jsonWrap.className = 'rounded bg-slate-100 p-3 text-xs text-slate-700 overflow-auto';
      root.appendChild(jsonWrap);
    }

    let textWrap = null;
    if (section.textConfig) {
      textWrap = document.createElement('div');
      textWrap.className = 'text-sm text-slate-600';
      root.appendChild(textWrap);
    }

    let markdownWrap = null;
    if (section.markdownConfig) {
      markdownWrap = document.createElement('div');
      markdownWrap.className = 'prose prose-slate max-w-none text-sm';
      root.appendChild(markdownWrap);
    }

    // Static HTML content
    if (section.htmlContent) {
      const htmlWrap = document.createElement('div');
      htmlWrap.innerHTML = section.htmlContent;
      root.appendChild(htmlWrap);
    }

    let customWrap = null;
    if (section.customRenderer) {
      customWrap = document.createElement('div');
      root.appendChild(customWrap);
    }

    let autoWrap = null;
    if (section.autoConfig) {
      autoWrap = document.createElement('div');
      root.appendChild(autoWrap);
    }

    if (section.actions.length > 0 && output) {
      root.appendChild(output);
    }

    const renderExtras = () => {
      const data = section.lastData ? section.lastData.data : null;
      if (autoWrap && section.autoConfig) {
        const payload = resolveSectionPayload(section.autoConfig.path, section.appStore, data);
        renderAuto(autoWrap, payload);
      }
      if (kpiWrap && section.kpiConfig) {
        renderKpis(kpiWrap, section.kpiConfig, section.appStore, data);
      }
      if (jsonWrap && section.jsonConfig) {
        const payload = resolveSectionPayload(section.jsonConfig.path, section.appStore, data);
        jsonWrap.innerHTML = formatJson(payload);
      }
      if (textWrap && section.textConfig) {
        const text = resolveText(section.textConfig.text, section.textConfig.path, section.appStore, data);
        textWrap.textContent = text;
      }
      if (markdownWrap && section.markdownConfig) {
        const text = resolveText(section.markdownConfig.text, section.markdownConfig.path, section.appStore, data);
        markdownWrap.innerHTML = markdownToHtml(text);
      }
      if (customWrap && section.customRenderer) {
        const result = section.customRenderer({ data, store: section.appStore }) || '';
        if (typeof result === 'string') {
          customWrap.innerHTML = result;
        } else if (result instanceof HTMLElement) {
          customWrap.innerHTML = '';
          customWrap.appendChild(result);
        }
      }
      if (section.renderHook) {
        section.renderHook({ data, store: section.appStore, element: root });
      }
    };

    const refresh = async () => {
      updateSelectBindings(selectBindings, section.appStore);
      if (section.readConfig) {
        const payload = buildQueryPayload(section, sectionInputs, section.appStore);
        const path = buildQueryPath(section.readConfig.path, payload);
        let data;
        try {
          data = await request(section.readConfig, null, false, payload, section.appStore, path);
          if (!data.ok && section.mockConfig) {
            throw new Error("Backend error");
          }
          root.classList.remove('is-mocked');
          root.style.borderStyle = '';
        } catch (e) {
          if (section.mockConfig || section.readConfig) {
            console.warn(`⚠️ Mocking data for section "${section.title}"`);
            let mockData;
            if (section.mockConfig) {
              mockData = typeof section.mockConfig === 'function' ? section.mockConfig(section.appStore) : section.mockConfig;
            } else {
              // Auto-inference logic
              if (section.listTemplate) {
                mockData = [
                  { id: 1, name: "Sample Item 1", amount: 100, description: "Mocked data" },
                  { id: 2, name: "Sample Item 2", amount: 200, description: "Mocked data" }
                ];
              } else if (section.kpiConfig) {
                mockData = {};
                section.kpiConfig.items.forEach(item => { if (item.key) mockData[item.key] = 0; });
              } else {
                mockData = { message: "Mocked response" };
              }
            }
            data = { ok: true, status: 200, json: { data: mockData }, data: mockData };
            root.classList.add('is-mocked');
            root.style.borderStyle = 'dashed';
            root.style.borderColor = '#cbd5e1'; // slate-300
            if (!root.querySelector('.mock-badge')) {
              const badge = document.createElement('span');
              badge.className = 'mock-badge ml-2 inline-flex items-center rounded-md bg-amber-50 px-2 py-1 text-xs font-medium text-amber-700 ring-1 ring-inset ring-amber-600/20';
              badge.textContent = 'MOCKED';
              root.querySelector('h2').appendChild(badge);
            }
          } else {
            root.classList.remove('is-mocked');
            root.style.borderStyle = '';
            const badge = root.querySelector('.mock-badge');
            if (badge) badge.remove();
            throw e;
          }
        }
        if (!root.classList.contains('is-mocked')) {
          const badge = root.querySelector('.mock-badge');
          if (badge) badge.remove();
        }
        section.lastData = data.json || null;
        applyStore(section.appStore, section.storeMap, data.json);
        const hasExplicitView = section.listFromPath || section.listTemplate || section.templateMode || section.kpiConfig || section.jsonConfig || section.textConfig || section.markdownConfig || section.customRenderer;
        if (!hasExplicitView && !section.autoConfig) {
          section.autoConfig = { path: section.listFromPath || 'data' };
        }
        if (section.listFromPath) {
          renderList(listWrap, section, { data: getPath(section.appStore, section.listFromPath) });
        } else if (section.listTemplate || section.templateMode) {
          renderList(listWrap, section, data);
        }
        if (metaEl && section.metaConfig) {
          let metaSource = section.metaConfig.path ? getPath(section.appStore, section.metaConfig.path) : (data.json ? data.json.data : null);
          if (Array.isArray(metaSource)) {
            metaSource = { count: metaSource.length };
          }
          metaEl.textContent = renderTemplate(section.metaConfig.template, metaSource || {}, section.appStore);
        }
        renderExtras();
        return;
      }
      if (section.listFromPath) {
        renderList(listWrap, section, { data: getPath(section.appStore, section.listFromPath) });
        if (metaEl && section.metaConfig) {
          let metaSource = section.metaConfig.path ? getPath(section.appStore, section.metaConfig.path) : getPath(section.appStore, section.listFromPath);
          if (Array.isArray(metaSource)) {
            metaSource = { count: metaSource.length };
          }
          metaEl.textContent = renderTemplate(section.metaConfig.template, metaSource || {}, section.appStore);
        }
        renderExtras();
        return;
      }
      if (section.storeViewConfig) {
        const value = section.appStore[section.storeViewConfig.key];
        const prevTemplate = section.listTemplate;
        if (section.storeViewConfig.template) {
          section.listTemplate = section.storeViewConfig.template;
        }
        renderList(listWrap, section, { data: value ? [{ [section.storeViewConfig.key]: value }] : [] });
        section.listTemplate = prevTemplate;
        renderExtras();
        return;
      }
      renderExtras();
    };

    section.refresh = refresh;

    window.addEventListener(`ui:refresh:${section.sectionId}`, refresh);

    return { root, refresh };
  }

  function renderWebSocketSection(section) {
    const root = document.createElement('section');
    root.className = 'rounded-xl border border-slate-200 bg-white p-6 shadow-sm space-y-4';

    const title = document.createElement('h2');
    title.className = 'text-lg font-semibold';
    title.textContent = section.title;
    root.appendChild(title);

    const wsUrl = section.wsConfig.url || `ws://${location.host}/ws`;
    const clients = section.wsConfig.clients || [];
    const historyUrl = section.wsConfig.history;

    const outputs = [];
    const sockets = [];

    if (clients.length > 0) {
      const grid = document.createElement('div');
      grid.className = 'grid gap-4 lg:grid-cols-2';
      clients.forEach((client) => {
        const card = document.createElement('div');
        card.className = 'rounded-xl border border-slate-200 bg-white p-4 shadow-sm';
        const heading = document.createElement('h3');
        heading.className = 'text-sm font-semibold';
        heading.textContent = client.label || 'Client';
        card.appendChild(heading);

        const row = document.createElement('div');
        row.className = 'mt-3 flex flex-wrap gap-2';
        const nameInput = document.createElement('input');
        nameInput.className = 'w-28 rounded border border-slate-300 px-3 py-2';
        nameInput.value = client.name || '';
        const msgInput = document.createElement('input');
        msgInput.className = 'flex-1 rounded border border-slate-300 px-3 py-2';
        msgInput.value = client.message || '';
        const sendBtn = document.createElement('button');
        sendBtn.className = 'rounded bg-slate-900 px-4 py-2 text-white';
        sendBtn.textContent = 'Send';
        row.appendChild(nameInput);
        row.appendChild(msgInput);
        row.appendChild(sendBtn);
        card.appendChild(row);

        const out = document.createElement('pre');
        out.className = 'mt-3 rounded bg-slate-100 p-3 text-xs text-slate-700';
        out.textContent = '-';
        card.appendChild(out);
        outputs.push(out);

        const ws = new WebSocket(wsUrl);
        ws.onopen = () => setFooter({ ok: true, status: 200, raw: `WebSocket connected (${client.label || 'client'})` });
        ws.onmessage = (event) => {
          out.textContent = event.data;
        };
        ws.onclose = () => setFooter({ ok: false, status: 500, error: { message: `WebSocket closed (${client.label || 'client'})` } });
        ws.onerror = () => setFooter({ ok: false, status: 500, error: { message: `WebSocket error (${client.label || 'client'})` } });
        sockets.push(ws);

        sendBtn.addEventListener('click', () => {
          if (ws.readyState !== WebSocket.OPEN) {
            setFooter({ ok: false, status: 500, error: { message: `${client.label || 'Client'} not connected.` } });
            return;
          }
          const name = nameInput.value || client.label || 'Client';
          ws.send(`${name}: ${msgInput.value}`);
        });

        grid.appendChild(card);
      });
      root.appendChild(grid);
    } else {
      const row = document.createElement('div');
      row.className = 'flex flex-wrap gap-2';
      const msgInput = document.createElement('input');
      msgInput.className = 'flex-1 rounded border border-slate-300 px-3 py-2';
      msgInput.value = section.wsConfig.message || 'hello';
      const connectBtn = document.createElement('button');
      connectBtn.className = 'rounded border border-slate-300 px-4 py-2';
      connectBtn.textContent = 'Connect';
      const sendBtn = document.createElement('button');
      sendBtn.className = 'rounded bg-slate-900 px-4 py-2 text-white';
      sendBtn.textContent = 'Send';
      row.appendChild(msgInput);
      row.appendChild(connectBtn);
      row.appendChild(sendBtn);
      root.appendChild(row);

      const out = document.createElement('pre');
      out.className = 'mt-3 rounded bg-slate-100 p-3 text-xs text-slate-700';
      out.textContent = '-';
      root.appendChild(out);

      const log = document.createElement('ul');
      log.className = 'mt-3 space-y-2 text-sm';
      root.appendChild(log);

      let ws = null;
      const connect = () => {
        ws = new WebSocket(wsUrl);
        ws.onopen = () => setFooter({ ok: true, status: 200, raw: 'WebSocket connected.' });
        ws.onmessage = (event) => {
          out.textContent = event.data;
          const li = document.createElement('li');
          li.className = 'rounded border border-slate-200 px-3 py-2';
          li.textContent = `${new Date().toLocaleTimeString()} ${event.data}`;
          log.prepend(li);
        };
        ws.onclose = () => setFooter({ ok: false, status: 500, error: { message: 'WebSocket closed.' } });
        ws.onerror = () => setFooter({ ok: false, status: 500, error: { message: 'WebSocket error.' } });
      };
      connectBtn.addEventListener('click', connect);
      sendBtn.addEventListener('click', () => {
        if (!ws || ws.readyState !== WebSocket.OPEN) {
          setFooter({ ok: false, status: 500, error: { message: 'Connect first.' } });
          return;
        }
        ws.send(msgInput.value);
      });
      if (section.wsConfig.autoConnect) {
        connect();
      }
    }

    if (historyUrl) {
      const historyWrap = document.createElement('div');
      historyWrap.className = 'rounded-xl border border-slate-200 bg-white p-4 shadow-sm';
      const header = document.createElement('div');
      header.className = 'flex items-center justify-between';
      const h = document.createElement('h3');
      h.className = 'text-sm font-semibold';
      h.textContent = 'Recent Messages';
      const refresh = document.createElement('button');
      refresh.className = 'rounded border border-slate-300 px-3 py-1 text-sm';
      refresh.textContent = 'Refresh';
      header.appendChild(h);
      header.appendChild(refresh);
      historyWrap.appendChild(header);

      const list = document.createElement('ul');
      list.className = 'mt-3 space-y-2 text-sm';
      historyWrap.appendChild(list);
      root.appendChild(historyWrap);

      const loadHistory = async () => {
        const res = await request({ method: 'GET', path: historyUrl }, null, false, {}, section.appStore);
        list.innerHTML = '';
        (res.data || []).forEach((msg) => {
          const li = document.createElement('li');
          li.className = 'rounded border border-slate-200 px-3 py-2';
          li.textContent = `${msg.at || ''} ${msg.message || msg}`;
          list.appendChild(li);
        });
      };
      refresh.addEventListener('click', loadHistory);
      loadHistory();
      if (section.wsConfig.pollHistory) {
        setInterval(loadHistory, section.wsConfig.pollHistory);
      }
    }

    return { root, refresh: async () => {} };
  }

  function renderList(target, section, payload) {
    target.innerHTML = '';
    const data = payload && payload.data !== undefined ? payload.data : payload;
    if (!data) {
      target.textContent = 'No data.';
      return;
    }
    const rows = Array.isArray(data) ? data : [data];
    if (rows.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'text-slate-500';
      empty.textContent = 'No items yet.';
      target.appendChild(empty);
      return;
    }
    // Table template mode
    if (section.templateMode === 'table' && rows.length > 0) {
      const table = document.createElement('table');
      table.className = 'w-full text-sm border-collapse';
      const keys = Object.keys(rows[0]);
      const thead = document.createElement('thead');
      thead.innerHTML = '<tr class="border-b border-slate-200">' + keys.map(k => `<th class="text-left py-2 px-3 font-medium text-slate-600">${k}</th>`).join('') + '</tr>';
      table.appendChild(thead);
      const tbody = document.createElement('tbody');
      rows.forEach(row => {
        const tr = document.createElement('tr');
        tr.className = 'border-b border-slate-100 hover:bg-slate-50';
        tr.innerHTML = keys.map(k => `<td class="py-2 px-3 text-slate-700">${row[k] ?? ''}</td>`).join('');
        tbody.appendChild(tr);
      });
      table.appendChild(tbody);
      target.appendChild(table);
      return;
    }
    rows.forEach((row) => {
      const card = document.createElement('div');
      card.className = 'rounded border border-slate-200 px-3 py-2 space-y-2';
      if (section.listTemplate) {
        const label = document.createElement('div');
        const rendered = renderTemplate(section.listTemplate, row);
        // Use innerHTML if template contains HTML tags, otherwise textContent
        if (/<[^>]+>/.test(rendered)) {
          label.innerHTML = rendered;
        } else {
          label.textContent = rendered;
        }
        card.appendChild(label);
      } else {
        const label = document.createElement('div');
        label.textContent = JSON.stringify(row);
        card.appendChild(label);
      }
      if (section.rowFields.length || section.rowActions.length) {
        const rowControls = document.createElement('div');
        rowControls.className = 'grid gap-2 sm:grid-cols-3';
        const rowInputs = {};
        section.rowFields.forEach((field) => {
          const prior = row && row[field.key] !== undefined ? row[field.key] : '';
          const input = renderField(field, section.appStore, row, prior);
          rowInputs[field.key] = input;
          rowControls.appendChild(input);
        });
        section.rowActions.forEach((action) => {
          const btn = document.createElement('button');
          btn.className = 'rounded border border-slate-300 px-3 py-2 text-sm';
          btn.textContent = action.label;
          btn.addEventListener('click', async () => {
            // Confirmation dialog if configured
            if (action.confirmMessage && !window.confirm(action.confirmMessage)) {
              return;
            }
            const fields = action.fieldList.length > 0 ? action.fieldList : section.rowFields;
            const body = collectFields(fields, rowInputs);
            const path = renderTemplate(action.path, row, section.appStore);
            const res = await request(action, body, action.withCreds, row, section.appStore, path);
            applyStore(section.appStore, action.storeMap, res.json);
            applySetMap(section.appStore, action.setMap, body, rowInputs);
            setFooter(res);
            if (action.refreshAllFlag && section.app.refreshAll) {
              await section.app.refreshAll();
            } else if (!section.noAutoRefresh && section.refresh && (section.readConfig || section.listFromPath || section.storeViewConfig)) {
              await section.refresh();
            }
          });
          rowControls.appendChild(btn);
        });
        card.appendChild(rowControls);
      }
      target.appendChild(card);
    });
  }

  function renderActionForm(action, output, appStore, sectionInputs, section, selectBindings) {
    const wrap = document.createElement('div');
    wrap.className = 'grid gap-2 sm:grid-cols-4';
    const fieldInputs = {};
    action.fieldList.forEach((field) => {
      const input = renderField(field, appStore);
      fieldInputs[field.key] = input;
      if (field.optionsFrom && selectBindings) {
        selectBindings.push({ field, input });
      }
      wrap.appendChild(input);
    });
    const btn = document.createElement('button');
    btn.className = 'rounded border border-slate-300 px-3 py-2 text-sm';
    btn.textContent = action.label;
    btn.addEventListener('click', async () => {
      // Confirmation dialog if configured
      if (action.confirmMessage && !window.confirm(action.confirmMessage)) {
        return;
      }
      const body = Object.assign({}, action.bodyMap, collectFields(action.fieldList, fieldInputs, sectionInputs));
      applySetMap(appStore, action.setMap, body, sectionInputs);
      applyAdjustments(appStore, action.adjustments, sectionInputs);
      const queryPayload = buildQueryPayload(section, sectionInputs, appStore);
      if (action.customHandler) {
        await action.customHandler({
          body,
          request: (path, opts) => request({ method: opts?.method || 'GET', path, headerMap: opts?.headers || {} }, opts?.body, action.withCreds, {}, appStore, path),
          store: appStore,
          output,
          setFooter
        });
        if (action.refreshAllFlag && section.app.refreshAll) {
          await section.app.refreshAll();
        } else if (!section.noAutoRefresh && (section.readConfig || section.listFromPath || section.storeViewConfig)) {
          await section.refresh();
        }
        return;
      }
      if (action.localOnly) {
        if (output) output.textContent = 'ok';
        setFooter({ ok: true, status: 200, raw: 'ok' });
        if (action.refreshAllFlag && section.app.refreshAll) {
          await section.app.refreshAll();
        } else if (!section.noAutoRefresh && (section.readConfig || section.listFromPath || section.storeViewConfig)) {
          await section.refresh();
        }
        return;
      }
      const overridePath = action.method === 'GET' && section.queryMap
        ? buildQueryPath(action.path, queryPayload)
        : null;
      const res = await request(action, body, action.withCreds, queryPayload, appStore, overridePath);
        if (output) output.textContent = res.raw || '-';
        applyStore(appStore, action.storeMap, res.json);
        applyHeaderStore(appStore, action.headerStoreMap, res.headers || {});
        syncInputs(appStore, fieldInputs);
        syncInputs(appStore, sectionInputs);
      setFooter(res);
      if (action.refreshAllFlag && section.app.refreshAll) {
        await section.app.refreshAll();
      } else if (!section.noAutoRefresh && (section.readConfig || section.listFromPath || section.storeViewConfig)) {
        await section.refresh();
      }
    });
    wrap.appendChild(btn);
    return wrap;
  }

  function renderField(field, store, row, keepValue) {
    const resolvedValue = resolveTemplateValue(field.value, store, row);
    if (field.type === 'select') {
      // Signature: chapter-6/6-2-sql-filters.
      // Signature: chapter-6/6-4-sql-joins (dynamic options).
      const select = document.createElement('select');
      select.className = 'rounded border border-slate-300 px-3 py-2 text-sm';
      select.name = field.key;
      if (field.options && field.options.length > 0) {
        (field.options || []).forEach((opt) => {
          const option = document.createElement('option');
          if (typeof opt === 'object') {
            option.value = opt.value;
            option.textContent = opt.label || opt.value;
          } else {
            option.value = opt;
            option.textContent = opt;
          }
          select.appendChild(option);
        });
      }
      if (keepValue && keepValue !== '') {
        select.value = keepValue;
      } else if (resolvedValue !== undefined) {
        select.value = resolvedValue;
      }
      return select;
    }
    if (field.type === 'textarea') {
      // Signature: chapter-5/5-4-webhooks payload editor.
      const area = document.createElement('textarea');
      area.className = 'rounded border border-slate-300 px-3 py-2 text-sm';
      area.name = field.key;
      area.rows = field.rows || 3;
      if (field.placeholder) area.placeholder = field.placeholder;
      if (keepValue && keepValue !== '') {
        area.value = keepValue;
      } else if (resolvedValue !== undefined) {
        area.value = resolvedValue;
      }
      return area;
    }
    const input = document.createElement('input');
    input.className = 'rounded border border-slate-300 px-3 py-2 text-sm';
    input.name = field.key;
    input.type = field.type || 'text';
    if (field.placeholder) input.placeholder = field.placeholder;
    if (keepValue && keepValue !== '' && field.type !== 'file') {
      input.value = keepValue;
    } else if (resolvedValue !== undefined && field.type !== 'file') {
      input.value = resolvedValue;
    }
    return input;
  }

  function resolveTemplateValue(value, store, row) {
    if (typeof value === 'string' && value.includes('{{')) {
      const rendered = renderTemplate(value, row || {}, store || {});
      return rendered === '' ? undefined : rendered;
    }
    return value;
  }

  function collectFields(fields, inputs, sectionInputs) {
    const out = {};
    fields.forEach((field) => {
      const input = inputs[field.key];
      if (!input) return;
      if (field.type === 'file') {
        out[field.key] = input.files && input.files[0];
      } else if (field.type === 'number') {
        out[field.key] = Number(input.value || 0);
      } else {
        out[field.key] = input.value;
      }
    });
    Object.entries(sectionInputs || {}).forEach(([key, input]) => {
      if (out[key] !== undefined) return;
      if (input.type === 'number') {
        out[key] = Number(input.value || 0);
      } else {
        out[key] = input.value;
      }
    });
    return out;
  }

  async function request(action, body, withCreds, row, appStore, overridePath) {
    const method = (action.method || 'GET').toUpperCase();
    const headers = {};
    const opts = { method };
    if (withCreds) opts.credentials = 'include';

    if (method === 'UPLOAD') {
      const form = new FormData();
      Object.entries(body || {}).forEach(([key, value]) => {
        if (value) form.append(key, value);
      });
      opts.method = 'POST';
      opts.body = form;
    } else if (method !== 'GET') {
      headers['Content-Type'] = 'application/json';
      opts.body = JSON.stringify(body || {});
    }

    const path = overridePath || action.path;
    applyAuth(headers, action, body, appStore);
    Object.entries(action.headerMap || {}).forEach(([key, value]) => {
      headers[key] = renderTemplate(String(value), body || row || {}, appStore);
    });
    if (Object.keys(headers).length > 0) {
      opts.headers = Object.assign({}, opts.headers || {}, headers);
    }

    const res = await fetch(path, opts);
    const raw = await res.text();
    let json = null;
    try {
      json = JSON.parse(raw);
    } catch {
      json = { error: { message: raw } };
    }
    const headerMap = {};
    res.headers.forEach((value, key) => {
      headerMap[key.toLowerCase()] = value;
    });
    return {
      ok: res.ok,
      status: res.status,
      data: json.data,
      error: json.error,
      raw,
      json,
      headers: headerMap
    };
  }

  function setFooter(result) {
    const msg = result.ok ? 'ok' : `error: ${result.error ? result.error.message : result.status}`;
    let hint = result.ok ? '' : 'Check required fields and rules.';
    if (result.headers && result.headers['x-request-id']) {
      hint = `request ${result.headers['x-request-id']}`;
    }
    const msgEl = document.getElementById('footerMsg');
    const hintEl = document.getElementById('footerHint');
    if (msgEl) msgEl.textContent = msg;
    if (hintEl) hintEl.textContent = hint;
  }

  function renderFooter() {
    const footer = document.createElement('footer');
    footer.className = 'fixed bottom-0 left-0 right-0 border-t border-slate-200 bg-white';
    footer.innerHTML = `
      <div class="mx-auto flex max-w-4xl items-start gap-4 px-6 py-3 text-sm">
        <div class="font-semibold text-slate-700">Status</div>
        <div class="flex-1">
          <div id="footerMsg" class="text-slate-700">Ready.</div>
          <div id="footerHint" class="text-slate-500"></div>
        </div>
      </div>
    `;
    return footer;
  }

  function ensureRoot(targetId) {
    let root = document.getElementById(targetId);
    if (!root) {
      root = document.createElement('div');
      root.id = targetId;
      document.body.appendChild(root);
    }
    document.body.className = 'min-h-screen bg-slate-50 text-slate-900';
    return root;
  }

  function slugify(value) {
    return (value || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  }

  function renderTemplate(template, data, store) {
    return template.replace(/{{\s*([\w.]+)\s*}}/g, (_, key) => {
      if (key === 'json') {
        return JSON.stringify(data);
      }
      const value = key.split('.').reduce((acc, part) => (acc ? acc[part] : undefined), data);
      if (value !== undefined && value !== null) {
        if (typeof value === 'object') {
          return JSON.stringify(value);
        }
        return String(value);
      }
      const fromStore = key.split('.').reduce((acc, part) => (acc ? acc[part] : undefined), store || {});
      if (fromStore !== undefined && fromStore !== null) {
        return String(fromStore);
      }
      return value === undefined || value === null ? '' : String(value);
    });
  }

  function normalizeField(key, value) {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      const hasValue = Object.prototype.hasOwnProperty.call(value, 'value');
      return {
        key,
        label: value.label,
        placeholder: value.placeholder,
        type: value.type || 'text',
        value: hasValue ? value.value : undefined,
        options: value.options,
        optionsFrom: value.optionsFrom,
        optionLabel: value.optionLabel,
        optionValue: value.optionValue
      };
    }
    return {
      key,
      type: typeof value === 'number' ? 'number' : 'text',
      value
    };
  }

  function normalizeFields(config) {
    return Object.entries(config || {}).map(([key, value]) => normalizeField(key, value));
  }

  function applyAuth(headers, action, body, store) {
    if (!action.authMode) return;
    if (action.authMode.type === 'basic') {
      // Used by chapter-3 auth basic.
      const user = lookupValue(action.authMode.userKey, body, store);
      const pass = lookupValue(action.authMode.passKey, body, store);
      const token = btoa(`${user || ''}:${pass || ''}`);
      headers['Authorization'] = `Basic ${token}`;
    } else if (action.authMode.type === 'bearer') {
      // Used by chapter-3 auth apikey/jwt/combined.
      const token = lookupValue(action.authMode.tokenKey, body, store);
      headers['Authorization'] = `Bearer ${token || ''}`;
    }
  }

  function applyStore(store, map, json) {
    if (!store || !map) return;
    Object.entries(map).forEach(([key, path]) => {
      const value = path.split('.').reduce((acc, part) => (acc ? acc[part] : undefined), json || {});
      if (value !== undefined) {
        store[key] = value;
      }
    });
  }

  function applyHeaderStore(store, map, headers) {
    if (!store || !map) return;
    Object.entries(map).forEach(([key, headerName]) => {
      const value = headers[headerName.toLowerCase()];
      if (value !== undefined) {
        store[key] = value;
      }
    });
  }

  function syncInputs(store, inputs) {
    if (!store || !inputs) return;
    Object.entries(inputs).forEach(([key, input]) => {
      if (store[key] === undefined) return;
      if (input.type === 'file') return;
      input.value = store[key];
    });
  }

  function applySetMap(store, map, body, inputs) {
    if (!store || !map) return;
    Object.entries(map).forEach(([key, value]) => {
      if (typeof value === 'string') {
        store[key] = renderTemplate(value, body || {}, store);
      } else {
        store[key] = value;
      }
      if (inputs && inputs[key]) {
        inputs[key].value = store[key];
      }
    });
  }

  function applyAdjustments(store, adjustments, inputs) {
    if (!store || !adjustments) return;
    adjustments.forEach((adj) => {
      const current = Number(store[adj.key] || 0);
      let delta = adj.delta;
      if (typeof delta === 'string') {
        delta = Number(renderTemplate(delta, {}, store));
      }
      let next = current + (Number(delta) || 0);
      if (adj.minValue !== undefined) {
        next = Math.max(adj.minValue, next);
      }
      store[adj.key] = next;
      if (inputs && inputs[adj.key]) {
        inputs[adj.key].value = next;
      }
    });
  }

  function buildQueryPayload(section, sectionInputs, store) {
    if (!section || !section.queryMap) return {};
    const payload = {};
    Object.entries(section.queryMap).forEach(([key, value]) => {
      if (typeof value === 'string') {
        payload[key] = renderTemplate(value, collectFields([], {}, sectionInputs), store);
      } else {
        payload[key] = value;
      }
      store[key] = payload[key];
    });
    return payload;
  }

  function buildQueryPath(base, payload) {
    if (!payload || Object.keys(payload).length === 0) return base;
    const params = new URLSearchParams();
    Object.entries(payload).forEach(([key, value]) => {
      if (value === '' || value === null || value === undefined) return;
      params.set(key, String(value));
    });
    const qs = params.toString();
    return qs ? `${base}?${qs}` : base;
  }

  function getPath(obj, path) {
    if (!obj || !path) return undefined;
    if (typeof path !== 'string') {
      console.error(`[ui.js] getPath expected a string path, got ${typeof path}:`, path);
      return undefined;
    }
    return path.split('.').reduce((acc, part) => (acc ? acc[part] : undefined), obj);
  }

  function updateSelectBindings(bindings, store) {
    if (!bindings || bindings.length === 0) return;
    bindings.forEach(({ field, input }) => {
      if (!field.optionsFrom) return;

      // Handle optionsFrom as object { store: "key", value: "id", label: "name" } or string "key"
      let storePath, valueKey, labelKey;
      if (typeof field.optionsFrom === 'string') {
        storePath = field.optionsFrom;
        valueKey = field.optionValue || 'id';
        labelKey = field.optionLabel || 'name';
      } else if (typeof field.optionsFrom === 'object') {
        storePath = field.optionsFrom.store;
        valueKey = field.optionsFrom.value || field.optionValue || 'id';
        labelKey = field.optionsFrom.label || field.optionLabel || 'name';
      } else {
        console.error(`[ui.js] optionsFrom must be a string or object, got:`, field.optionsFrom);
        return;
      }

      const list = getPath(store, storePath);
      if (!Array.isArray(list)) {
        if (list !== undefined) {
          console.warn(`[ui.js] optionsFrom "${storePath}" is not an array:`, list);
        }
        return;
      }

      const current = input.value;
      input.innerHTML = '';
      list.forEach((row) => {
        const option = document.createElement('option');
        const value = getPath(row, valueKey) ?? row.id ?? row.name ?? row.value ?? '';
        option.value = value;
        const label = getPath(row, labelKey) ?? String(value);
        option.textContent = label;
        input.appendChild(option);
      });
      if (current) {
        input.value = current;
      }
    });
  }

  function lookupValue(key, body, store) {
    if (body && body[key] !== undefined) return body[key];
    if (store && store[key] !== undefined) return store[key];
    return '';
  }

  function renderKpis(container, config, store, data) {
    // Signature: chapter-4/4-6-caching, chapter-6/6-1-sql-basics.
    container.innerHTML = '';
    const items = config.items || [];
    items.forEach((item) => {
      const card = document.createElement('div');
      card.className = 'rounded-xl border border-slate-200 bg-white p-4 shadow-sm';
      const label = document.createElement('div');
      label.className = 'text-xs uppercase tracking-wide text-slate-500';
      label.textContent = item.label || '';
      const value = document.createElement('div');
      value.className = 'mt-2 text-2xl font-semibold text-slate-900';
      let resolved = '';
      if (typeof item.compute === 'function') {
        const computed = item.compute(data, store);
        resolved = computed === undefined || computed === null ? '' : String(computed);
      } else {
        resolved = resolveText(item.value || '', item.path, store, data);
      }
      value.textContent = resolved;
      card.appendChild(label);
      card.appendChild(value);
      container.appendChild(card);
    });
  }

  function resolveSectionPayload(path, store, data) {
    if (path) {
      return getPath(store, path) ?? getPath({ data }, path);
    }
    return data;
  }

  function resolveText(text, path, store, data) {
    if (path) {
      const payload = resolveSectionPayload(path, store, data);
      return typeof payload === 'string' ? payload : JSON.stringify(payload ?? '');
    }
    if (typeof text === 'string' && text.includes('{{')) {
      return renderTemplate(text, data || {}, store || {});
    }
    return text || '';
  }

  function formatJson(value) {
    // Signature: chapter-4/4-7-observability colored JSON.
    const json = JSON.stringify(value ?? {}, null, 2);
    const escaped = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    return escaped.replace(/(\".*?\"|\btrue\b|\bfalse\b|\bnull\b|\b-?\d+(\.\d+)?\b)/g, (match) => {
      if (match === 'true' || match === 'false') return `<span class="text-emerald-700">${match}</span>`;
      if (match === 'null') return `<span class="text-slate-500">${match}</span>`;
      if (match.startsWith('"')) return `<span class="text-sky-700">${match}</span>`;
      return `<span class="text-amber-700">${match}</span>`;
    });
  }

  function markdownToHtml(text) {
    // Signature: chapter-4/4-1-validation rules block.
    const lines = (text || '').split('\n');
    const out = [];
    let inList = false;
    lines.forEach((line) => {
      if (/^\s*-\s+/.test(line)) {
        if (!inList) {
          out.push('<ul class="list-disc pl-5 space-y-1">');
          inList = true;
        }
        const item = line.replace(/^\s*-\s+/, '');
        out.push(`<li>${inlineMarkdown(item)}</li>`);
        return;
      }
      if (inList) {
        out.push('</ul>');
        inList = false;
      }
      if (/^###\s+/.test(line)) {
        out.push(`<h3 class="text-sm font-semibold text-slate-700">${inlineMarkdown(line.replace(/^###\s+/, ''))}</h3>`);
        return;
      }
      if (/^##\s+/.test(line)) {
        out.push(`<h2 class="text-base font-semibold text-slate-800">${inlineMarkdown(line.replace(/^##\s+/, ''))}</h2>`);
        return;
      }
      if (/^#\s+/.test(line)) {
        out.push(`<h1 class="text-lg font-semibold text-slate-900">${inlineMarkdown(line.replace(/^#\s+/, ''))}</h1>`);
        return;
      }
      if (line.trim() === '') {
        out.push('<div class="h-2"></div>');
        return;
      }
      out.push(`<p class="text-sm text-slate-600">${inlineMarkdown(line)}</p>`);
    });
    if (inList) out.push('</ul>');
    return out.join('');
  }

  function inlineMarkdown(text) {
    let escaped = (text || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    escaped = escaped.replace(/`([^`]+)`/g, '<code class="rounded bg-slate-100 px-1 py-0.5 text-xs">$1</code>');
    escaped = escaped.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    escaped = escaped.replace(/\*([^*]+)\*/g, '<em>$1</em>');
    return escaped;
  }

  function renderAuto(container, payload) {
    container.innerHTML = '';
    if (payload === undefined || payload === null) {
      container.textContent = 'No data.';
      container.className = 'text-sm text-slate-500';
      return;
    }
    if (Array.isArray(payload)) {
      const list = document.createElement('div');
      list.className = 'space-y-2';
      payload.forEach((row) => {
        const card = document.createElement('div');
        card.className = 'rounded border border-slate-200 bg-white p-3 text-sm';
        if (typeof row === 'object') {
          card.innerHTML = formatJson(row);
        } else {
          card.textContent = String(row);
        }
        list.appendChild(card);
      });
      container.appendChild(list);
      return;
    }
    if (typeof payload === 'object') {
      const grid = document.createElement('div');
      grid.className = 'grid gap-3 sm:grid-cols-3';
      Object.entries(payload).forEach(([key, value]) => {
        const card = document.createElement('div');
        card.className = 'rounded-xl border border-slate-200 bg-white p-4 shadow-sm';
        const label = document.createElement('div');
        label.className = 'text-xs uppercase tracking-wide text-slate-500';
        label.textContent = key;
        const val = document.createElement('div');
        val.className = 'mt-2 text-2xl font-semibold text-slate-900';
        val.textContent = typeof value === 'object' ? JSON.stringify(value) : String(value);
        card.appendChild(label);
        card.appendChild(val);
        grid.appendChild(card);
      });
      container.appendChild(grid);
      return;
    }
    const kpi = document.createElement('div');
    kpi.className = 'rounded-xl border border-slate-200 bg-white p-6 text-center shadow-sm';
    kpi.innerHTML = `<div class=\"text-xs uppercase tracking-wide text-slate-500\">value</div><div class=\"mt-2 text-3xl font-semibold text-slate-900\">${payload}</div>`;
    container.appendChild(kpi);
  }

  function autoMountPending() {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        pendingApps.forEach((builder) => builder.mount('app'));
        pendingApps.length = 0;
        autoMountScheduled = false;
      });
    } else {
      pendingApps.forEach((builder) => builder.mount('app'));
      pendingApps.length = 0;
      autoMountScheduled = false;
    }
  }

  function scheduleAutoMount() {
    if (autoMountScheduled) return;
    autoMountScheduled = true;
    if (document.readyState === 'loading') {
      autoMountPending();
    } else {
      queueMicrotask(autoMountPending);
    }
  }

  function loadScript(url) {
    return new Promise((resolve, reject) => {
      if (document.querySelector(`script[src="${url}"]`)) return resolve();
      const s = document.createElement('script');
      s.src = url;
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  function loadCSS(url) {
    if (document.querySelector(`link[href="${url}"]`)) return;
    const l = document.createElement('link');
    l.rel = 'stylesheet';
    l.href = url;
    document.head.appendChild(l);
  }

  autoMountPending();

  // Global listener to bridge ui-refresh events to section-specific events
  window.addEventListener('ui-refresh', (e) => {
    const id = e.detail && e.detail.id;
    if (id) {
      window.dispatchEvent(new CustomEvent(`ui:refresh:${id}`));
    }
  });

  return { app, mount, loadScript, loadCSS };
})();

export default ui;
