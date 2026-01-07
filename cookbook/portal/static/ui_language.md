# UI Builder Language 🪄

The Zauberflöte UI library is a minimal, reactive DSL for rapid prototyping. It focuses on binding UI components directly to backend API resources.

## Core Concepts

- **App**: The root container for your page.
- **Section**: A standalone card representing a piece of functionality.
- **Group**: A layout container for organizing sections (e.g., side-by-side grids).
- **Actions**: Explicit side-effects (GET, POST, etc.) that can refresh the UI.

## The DSL in Action

```javascript
import ui from "https://unpkg.com/zauberflote/src/ui.js";

ui.app("My App")
  .section("Income")
    .read("/income")
    .list("$ {{amount}}")
    .action("Add").post("/income/add")
      .field("amount", 100, "number").end()
  .mount();
```

## API Reference

### App & Layout
- `.app(title)`: Initialize the app.
- `.blurb(text)`: Add a subtitle to the app or group.
- `.group(title)`: Start a group of sections.
- `.grid(cols)`: Render group sections in a grid layout.
- `.section(title)`: Start a new functional card.
- `.end()`: Close a group or section and return to the parent.

### Views (Inside Section)
- `.read(url)`: Bind the section to a GET endpoint. Refreshes automatically after actions.
- `.list(template)`: Render rows using `{{key}}` placeholders.
- `.jsonView(path)`: Render data as syntax-highlighted JSON.
- `.kpis(items)`: Render big numbers (e.g., `[{label: "Total", value: "{{amount}}"}]`).
- `.markdown(text)`: Render formatted text.
- `.auto()`: Let the library choose the best view based on the data shape.

### Actions (Inside Section or Row)
- `.action(label)`: Add a button/form to the section.
- `.rowAction(label)`: Add a button to every row in a list.
- `.get(url)`, `.post(url)`, `.put(url)`, `.del(url)`: Set the HTTP method and path.
- `.field(key, defaultValue, type)`: Add an input field to the action.
- `.refreshAll()`: Force all sections in the app to reload after this action.
- `.creds()`: Include cookies/credentials in the request.

### State & Store
- `.store({ key: "path.to.data" })`: Map API response data into the global app store.
- `.headers({ "X-My-Header": "{{store_key}}" })`: Dynamically set headers from the store.

---

*“Zauberflöte UI” - Speed of thought for your frontend.*