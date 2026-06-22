"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/calculate-income.tsx
var calculate_income_exports = {};
__export(calculate_income_exports, {
  default: () => Command
});
module.exports = __toCommonJS(calculate_income_exports);
var import_api = require("@raycast/api");
var import_react = require("react");
var import_jsx_runtime = require("react/jsx-runtime");
var currency = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD"
});
function parseRate(value, fallback) {
  const n = Number.parseFloat(value);
  return Number.isFinite(n) ? n : fallback;
}
function buildMarkdown(b) {
  return `# Income Breakdown

**Payment:** ${currency.format(b.amount)}

| Bucket | Rate | Amount |
| --- | ---: | ---: |
| Taxes | ${b.taxRate}% | ${currency.format(b.tax)} |
| Owner | ${b.ownerRate}% | ${currency.format(b.owner)} |
| Operating Expenses | ${b.opexRate}% | ${currency.format(b.opex)} |
| **Total** | **${b.taxRate + b.ownerRate + b.opexRate}%** | **${currency.format(b.tax + b.owner + b.opex)}** |
`;
}
function ResultView({ breakdown }) {
  const plain = [
    `Payment: ${currency.format(breakdown.amount)}`,
    `Taxes (${breakdown.taxRate}%): ${currency.format(breakdown.tax)}`,
    `Owner (${breakdown.ownerRate}%): ${currency.format(breakdown.owner)}`,
    `Operating Expenses (${breakdown.opexRate}%): ${currency.format(breakdown.opex)}`
  ].join("\n");
  return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
    import_api.Detail,
    {
      markdown: buildMarkdown(breakdown),
      actions: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.ActionPanel, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.Action.CopyToClipboard, { title: "Copy Full Breakdown", content: plain }),
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
          import_api.Action.CopyToClipboard,
          {
            title: "Copy Taxes Amount",
            content: breakdown.tax.toFixed(2)
          }
        ),
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
          import_api.Action.CopyToClipboard,
          {
            title: "Copy Owner Amount",
            content: breakdown.owner.toFixed(2)
          }
        ),
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
          import_api.Action.CopyToClipboard,
          {
            title: "Copy Operating Amount",
            content: breakdown.opex.toFixed(2)
          }
        )
      ] })
    }
  );
}
function Command() {
  const prefs = (0, import_api.getPreferenceValues)();
  const taxRate = parseRate(prefs.taxRate, 30);
  const ownerRate = parseRate(prefs.ownerRate, 60);
  const opexRate = parseRate(prefs.opexRate, 10);
  const { push } = (0, import_api.useNavigation)();
  const [amountError, setAmountError] = (0, import_react.useState)();
  async function handleSubmit(values) {
    const amount = Number.parseFloat(values.amount.replace(/[$,\s]/g, ""));
    if (!Number.isFinite(amount) || amount < 0) {
      setAmountError("Enter a valid amount");
      return;
    }
    const breakdown = {
      amount,
      taxRate,
      ownerRate,
      opexRate,
      tax: amount * (taxRate / 100),
      owner: amount * (ownerRate / 100),
      opex: amount * (opexRate / 100)
    };
    if (taxRate + ownerRate + opexRate !== 100) {
      await (0, import_api.showToast)({
        style: import_api.Toast.Style.Failure,
        title: "Rates don't add up to 100%",
        message: `Currently ${taxRate + ownerRate + opexRate}%. Check the extension preferences.`
      });
    }
    await import_api.Clipboard.copy(breakdown.owner.toFixed(2));
    push(/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ResultView, { breakdown }));
  }
  return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(
    import_api.Form,
    {
      actions: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.ActionPanel, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
        import_api.Action.SubmitForm,
        {
          title: "Calculate",
          icon: import_api.Icon.Calculator,
          onSubmit: handleSubmit
        }
      ) }),
      children: [
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
          import_api.Form.Description,
          {
            text: `Taxes ${taxRate}% \xB7 Owner ${ownerRate}% \xB7 Operating ${opexRate}%`
          }
        ),
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
          import_api.Form.TextField,
          {
            id: "amount",
            title: "Payment Amount",
            placeholder: "e.g. 5000",
            autoFocus: true,
            error: amountError,
            onChange: () => amountError && setAmountError(void 0)
          }
        )
      ]
    }
  );
}
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vLi4vUmVwb3MvcmF5Y2FzdC9leHRlbnNpb25zL2luY29tZS1jYWxjdWxhdG9yL3NyYy9jYWxjdWxhdGUtaW5jb21lLnRzeCJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiaW1wb3J0IHtcbiAgQWN0aW9uLFxuICBBY3Rpb25QYW5lbCxcbiAgQ2xpcGJvYXJkLFxuICBEZXRhaWwsXG4gIEZvcm0sXG4gIEljb24sXG4gIGdldFByZWZlcmVuY2VWYWx1ZXMsXG4gIHNob3dUb2FzdCxcbiAgVG9hc3QsXG4gIHVzZU5hdmlnYXRpb24sXG59IGZyb20gXCJAcmF5Y2FzdC9hcGlcIjtcbmltcG9ydCB7IHVzZVN0YXRlIH0gZnJvbSBcInJlYWN0XCI7XG5cbmludGVyZmFjZSBQcmVmZXJlbmNlcyB7XG4gIHRheFJhdGU6IHN0cmluZztcbiAgb3duZXJSYXRlOiBzdHJpbmc7XG4gIG9wZXhSYXRlOiBzdHJpbmc7XG59XG5cbmludGVyZmFjZSBCcmVha2Rvd24ge1xuICBhbW91bnQ6IG51bWJlcjtcbiAgdGF4UmF0ZTogbnVtYmVyO1xuICBvd25lclJhdGU6IG51bWJlcjtcbiAgb3BleFJhdGU6IG51bWJlcjtcbiAgdGF4OiBudW1iZXI7XG4gIG93bmVyOiBudW1iZXI7XG4gIG9wZXg6IG51bWJlcjtcbn1cblxuY29uc3QgY3VycmVuY3kgPSBuZXcgSW50bC5OdW1iZXJGb3JtYXQoXCJlbi1VU1wiLCB7XG4gIHN0eWxlOiBcImN1cnJlbmN5XCIsXG4gIGN1cnJlbmN5OiBcIlVTRFwiLFxufSk7XG5cbmZ1bmN0aW9uIHBhcnNlUmF0ZSh2YWx1ZTogc3RyaW5nLCBmYWxsYmFjazogbnVtYmVyKTogbnVtYmVyIHtcbiAgY29uc3QgbiA9IE51bWJlci5wYXJzZUZsb2F0KHZhbHVlKTtcbiAgcmV0dXJuIE51bWJlci5pc0Zpbml0ZShuKSA/IG4gOiBmYWxsYmFjaztcbn1cblxuZnVuY3Rpb24gYnVpbGRNYXJrZG93bihiOiBCcmVha2Rvd24pOiBzdHJpbmcge1xuICByZXR1cm4gYCMgSW5jb21lIEJyZWFrZG93blxuXG4qKlBheW1lbnQ6KiogJHtjdXJyZW5jeS5mb3JtYXQoYi5hbW91bnQpfVxuXG58IEJ1Y2tldCB8IFJhdGUgfCBBbW91bnQgfFxufCAtLS0gfCAtLS06IHwgLS0tOiB8XG58IFRheGVzIHwgJHtiLnRheFJhdGV9JSB8ICR7Y3VycmVuY3kuZm9ybWF0KGIudGF4KX0gfFxufCBPd25lciB8ICR7Yi5vd25lclJhdGV9JSB8ICR7Y3VycmVuY3kuZm9ybWF0KGIub3duZXIpfSB8XG58IE9wZXJhdGluZyBFeHBlbnNlcyB8ICR7Yi5vcGV4UmF0ZX0lIHwgJHtjdXJyZW5jeS5mb3JtYXQoYi5vcGV4KX0gfFxufCAqKlRvdGFsKiogfCAqKiR7Yi50YXhSYXRlICsgYi5vd25lclJhdGUgKyBiLm9wZXhSYXRlfSUqKiB8ICoqJHtjdXJyZW5jeS5mb3JtYXQoYi50YXggKyBiLm93bmVyICsgYi5vcGV4KX0qKiB8XG5gO1xufVxuXG5mdW5jdGlvbiBSZXN1bHRWaWV3KHsgYnJlYWtkb3duIH06IHsgYnJlYWtkb3duOiBCcmVha2Rvd24gfSkge1xuICBjb25zdCBwbGFpbiA9IFtcbiAgICBgUGF5bWVudDogJHtjdXJyZW5jeS5mb3JtYXQoYnJlYWtkb3duLmFtb3VudCl9YCxcbiAgICBgVGF4ZXMgKCR7YnJlYWtkb3duLnRheFJhdGV9JSk6ICR7Y3VycmVuY3kuZm9ybWF0KGJyZWFrZG93bi50YXgpfWAsXG4gICAgYE93bmVyICgke2JyZWFrZG93bi5vd25lclJhdGV9JSk6ICR7Y3VycmVuY3kuZm9ybWF0KGJyZWFrZG93bi5vd25lcil9YCxcbiAgICBgT3BlcmF0aW5nIEV4cGVuc2VzICgke2JyZWFrZG93bi5vcGV4UmF0ZX0lKTogJHtjdXJyZW5jeS5mb3JtYXQoYnJlYWtkb3duLm9wZXgpfWAsXG4gIF0uam9pbihcIlxcblwiKTtcblxuICByZXR1cm4gKFxuICAgIDxEZXRhaWxcbiAgICAgIG1hcmtkb3duPXtidWlsZE1hcmtkb3duKGJyZWFrZG93bil9XG4gICAgICBhY3Rpb25zPXtcbiAgICAgICAgPEFjdGlvblBhbmVsPlxuICAgICAgICAgIDxBY3Rpb24uQ29weVRvQ2xpcGJvYXJkIHRpdGxlPVwiQ29weSBGdWxsIEJyZWFrZG93blwiIGNvbnRlbnQ9e3BsYWlufSAvPlxuICAgICAgICAgIDxBY3Rpb24uQ29weVRvQ2xpcGJvYXJkXG4gICAgICAgICAgICB0aXRsZT1cIkNvcHkgVGF4ZXMgQW1vdW50XCJcbiAgICAgICAgICAgIGNvbnRlbnQ9e2JyZWFrZG93bi50YXgudG9GaXhlZCgyKX1cbiAgICAgICAgICAvPlxuICAgICAgICAgIDxBY3Rpb24uQ29weVRvQ2xpcGJvYXJkXG4gICAgICAgICAgICB0aXRsZT1cIkNvcHkgT3duZXIgQW1vdW50XCJcbiAgICAgICAgICAgIGNvbnRlbnQ9e2JyZWFrZG93bi5vd25lci50b0ZpeGVkKDIpfVxuICAgICAgICAgIC8+XG4gICAgICAgICAgPEFjdGlvbi5Db3B5VG9DbGlwYm9hcmRcbiAgICAgICAgICAgIHRpdGxlPVwiQ29weSBPcGVyYXRpbmcgQW1vdW50XCJcbiAgICAgICAgICAgIGNvbnRlbnQ9e2JyZWFrZG93bi5vcGV4LnRvRml4ZWQoMil9XG4gICAgICAgICAgLz5cbiAgICAgICAgPC9BY3Rpb25QYW5lbD5cbiAgICAgIH1cbiAgICAvPlxuICApO1xufVxuXG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiBDb21tYW5kKCkge1xuICBjb25zdCBwcmVmcyA9IGdldFByZWZlcmVuY2VWYWx1ZXM8UHJlZmVyZW5jZXM+KCk7XG4gIGNvbnN0IHRheFJhdGUgPSBwYXJzZVJhdGUocHJlZnMudGF4UmF0ZSwgMzApO1xuICBjb25zdCBvd25lclJhdGUgPSBwYXJzZVJhdGUocHJlZnMub3duZXJSYXRlLCA2MCk7XG4gIGNvbnN0IG9wZXhSYXRlID0gcGFyc2VSYXRlKHByZWZzLm9wZXhSYXRlLCAxMCk7XG5cbiAgY29uc3QgeyBwdXNoIH0gPSB1c2VOYXZpZ2F0aW9uKCk7XG4gIGNvbnN0IFthbW91bnRFcnJvciwgc2V0QW1vdW50RXJyb3JdID0gdXNlU3RhdGU8c3RyaW5nIHwgdW5kZWZpbmVkPigpO1xuXG4gIGFzeW5jIGZ1bmN0aW9uIGhhbmRsZVN1Ym1pdCh2YWx1ZXM6IHsgYW1vdW50OiBzdHJpbmcgfSkge1xuICAgIGNvbnN0IGFtb3VudCA9IE51bWJlci5wYXJzZUZsb2F0KHZhbHVlcy5hbW91bnQucmVwbGFjZSgvWyQsXFxzXS9nLCBcIlwiKSk7XG4gICAgaWYgKCFOdW1iZXIuaXNGaW5pdGUoYW1vdW50KSB8fCBhbW91bnQgPCAwKSB7XG4gICAgICBzZXRBbW91bnRFcnJvcihcIkVudGVyIGEgdmFsaWQgYW1vdW50XCIpO1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIGNvbnN0IGJyZWFrZG93bjogQnJlYWtkb3duID0ge1xuICAgICAgYW1vdW50LFxuICAgICAgdGF4UmF0ZSxcbiAgICAgIG93bmVyUmF0ZSxcbiAgICAgIG9wZXhSYXRlLFxuICAgICAgdGF4OiBhbW91bnQgKiAodGF4UmF0ZSAvIDEwMCksXG4gICAgICBvd25lcjogYW1vdW50ICogKG93bmVyUmF0ZSAvIDEwMCksXG4gICAgICBvcGV4OiBhbW91bnQgKiAob3BleFJhdGUgLyAxMDApLFxuICAgIH07XG5cbiAgICBpZiAodGF4UmF0ZSArIG93bmVyUmF0ZSArIG9wZXhSYXRlICE9PSAxMDApIHtcbiAgICAgIGF3YWl0IHNob3dUb2FzdCh7XG4gICAgICAgIHN0eWxlOiBUb2FzdC5TdHlsZS5GYWlsdXJlLFxuICAgICAgICB0aXRsZTogXCJSYXRlcyBkb24ndCBhZGQgdXAgdG8gMTAwJVwiLFxuICAgICAgICBtZXNzYWdlOiBgQ3VycmVudGx5ICR7dGF4UmF0ZSArIG93bmVyUmF0ZSArIG9wZXhSYXRlfSUuIENoZWNrIHRoZSBleHRlbnNpb24gcHJlZmVyZW5jZXMuYCxcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIGF3YWl0IENsaXBib2FyZC5jb3B5KGJyZWFrZG93bi5vd25lci50b0ZpeGVkKDIpKTtcbiAgICBwdXNoKDxSZXN1bHRWaWV3IGJyZWFrZG93bj17YnJlYWtkb3dufSAvPik7XG4gIH1cblxuICByZXR1cm4gKFxuICAgIDxGb3JtXG4gICAgICBhY3Rpb25zPXtcbiAgICAgICAgPEFjdGlvblBhbmVsPlxuICAgICAgICAgIDxBY3Rpb24uU3VibWl0Rm9ybVxuICAgICAgICAgICAgdGl0bGU9XCJDYWxjdWxhdGVcIlxuICAgICAgICAgICAgaWNvbj17SWNvbi5DYWxjdWxhdG9yfVxuICAgICAgICAgICAgb25TdWJtaXQ9e2hhbmRsZVN1Ym1pdH1cbiAgICAgICAgICAvPlxuICAgICAgICA8L0FjdGlvblBhbmVsPlxuICAgICAgfVxuICAgID5cbiAgICAgIDxGb3JtLkRlc2NyaXB0aW9uXG4gICAgICAgIHRleHQ9e2BUYXhlcyAke3RheFJhdGV9JSBcdTAwQjcgT3duZXIgJHtvd25lclJhdGV9JSBcdTAwQjcgT3BlcmF0aW5nICR7b3BleFJhdGV9JWB9XG4gICAgICAvPlxuICAgICAgPEZvcm0uVGV4dEZpZWxkXG4gICAgICAgIGlkPVwiYW1vdW50XCJcbiAgICAgICAgdGl0bGU9XCJQYXltZW50IEFtb3VudFwiXG4gICAgICAgIHBsYWNlaG9sZGVyPVwiZS5nLiA1MDAwXCJcbiAgICAgICAgYXV0b0ZvY3VzXG4gICAgICAgIGVycm9yPXthbW91bnRFcnJvcn1cbiAgICAgICAgb25DaGFuZ2U9eygpID0+IGFtb3VudEVycm9yICYmIHNldEFtb3VudEVycm9yKHVuZGVmaW5lZCl9XG4gICAgICAvPlxuICAgIDwvRm9ybT5cbiAgKTtcbn1cbiJdLAogICJtYXBwaW5ncyI6ICI7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBLGlCQVdPO0FBQ1AsbUJBQXlCO0FBc0RqQjtBQXBDUixJQUFNLFdBQVcsSUFBSSxLQUFLLGFBQWEsU0FBUztBQUFBLEVBQzlDLE9BQU87QUFBQSxFQUNQLFVBQVU7QUFDWixDQUFDO0FBRUQsU0FBUyxVQUFVLE9BQWUsVUFBMEI7QUFDMUQsUUFB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
