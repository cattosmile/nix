import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property real borderThickness

    readonly property alias activationRegion: activationZone
    readonly property alias interactionRegion: panelInteraction
    readonly property alias dismissalRegion: dismissalZone
    readonly property real surfaceWidth: 640
    readonly property real baseSurfaceHeight: 72
    readonly property real resultRowStep: 48
    readonly property real resultRowHeight: 40
    readonly property real surfaceCornerRadius: 20
    readonly property real surfaceInset: 16
    readonly property real searchCornerRadius:
        Math.max(0, surfaceCornerRadius - surfaceInset)
    // Keep the entire query inside the search field.  Iosevka is monospaced,
    // so measuring one representative glyph gives us a stable character
    // budget that prevents TextInput from horizontally scrolling the leading
    // `>` out of view.
    readonly property real searchTextWidth:
        surfaceWidth - 2 * surfaceInset - 32
    readonly property real searchCharacterWidth:
        Math.max(1, searchTextMetrics.advanceWidth)
    readonly property int searchMaximumLength:
        Math.max(
            1,
            Math.floor(
                Math.max(0, searchTextWidth)
                    / searchCharacterWidth
            )
        )
    readonly property real surfaceX: (width - surfaceWidth) / 2
    readonly property real visibleY: borderThickness - 2
    readonly property real hiddenY: -surfaceHeight - 4
    readonly property bool virtualMachineShutdownMode:
        virtualMachineConfirmationEntry !== null
    readonly property bool virtualMachineQueryMode:
        isVirtualMachineQuery(searchInput.text)
    readonly property bool systemCommandMode:
        isSystemCommandQuery(searchInput.text)
    readonly property bool calculatorMode:
        isCalculatorQuery(searchInput.text)
    readonly property bool virtualMachineMode:
        virtualMachineShutdownMode || virtualMachineQueryMode
    readonly property var results: virtualMachineShutdownMode
        ? virtualMachineConfirmationOptions
        : virtualMachineQueryMode
        ? virtualMachineEntries
        : systemCommandMode
        ? systemCommandResults
        : calculatorMode
        ? calculatorResults
        : searchApplications()
    readonly property real targetSurfaceHeight:
        baseSurfaceHeight + results.length * resultRowStep
    readonly property bool pointerInside:
        activationHover.hovered || panelHover.hovered

    // Keep this as an initial value rather than a binding to hiddenY. When
    // results resize the panel, a hiddenY binding would snap an open panel
    // back off-screen while the user is typing.
    property real surfaceY: -76
    property real surfaceHeight: targetSurfaceHeight
    property bool openRequested: false
    property bool surfaceVisible: false
    property bool dismissalCaptureActive: false
    property bool keyboardActive: false
    property bool edgeCloseArmed: false
    property bool edgeClosePrimed: false
    property int selectedIndex: 0
    property var virtualMachineEntries: []
    property var virtualMachineConfirmationEntry: null
    property string virtualMachineQueryText: ""
    readonly property var virtualMachineConfirmationOptions: [
        { name: "Yes", action: "shutdown" },
        { name: "No", action: "cancel" },
        { name: "Force Shut Off", action: "forceShutdown" }
    ]
    readonly property var systemCommandDefinitions: [
        {
            name: "Shutdown",
            command: "shutdown",
            glyph: "\uf011"
        },
        {
            name: "Reboot",
            command: "reboot",
            glyph: "\uf2f1"
        },
        {
            name: "Log out",
            command: "logout",
            glyph: "\uf2f5"
        }
    ]
    readonly property var systemCommandResults: systemCommandEntries()
    readonly property var calculatorResults: calculatorEntries()

    TextMetrics {
        id: searchTextMetrics

        font {
            family: "Iosevka"
            pixelSize: 16
        }
        text: "0"
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.openRequested)
                root.requestClose();
            else
                root.requestOpen();
        }

        function open(): void {
            root.requestOpen();
        }

        function close(): void {
            root.requestClose();
        }

    }

    function searchableText(entry) {
        const keywords = entry.keywords
            ? Array.from(entry.keywords).join("")
            : "";
        const categories = entry.categories
            ? Array.from(entry.categories).join("")
            : "";

        // Wofi's drun mode concatenates all searchable desktop metadata into
        // one string before applying multi-contains.
        return [
            entry.name || "",
            entry.id || "",
            entry.execString || "",
            entry.comment || "",
            categories,
            keywords,
            entry.genericName || ""
        ].join("").toLocaleLowerCase();
    }

    function applicationIcon(entry) {
        return Quickshell.iconPath(
            entry.icon || "application-default-icon",
            "application-default-icon"
        );
    }

    function isVirtualMachineQuery(rawQuery) {
        const query = String(rawQuery || "").trim().toLocaleLowerCase();

        if (!query.startsWith(">"))
            return false;

        // Keep this deliberately narrow: accept only prefixes of "windows"
        // starting at "win", so arbitrary strings such as >Windudasd do not
        // switch the launcher into VM mode.
        const term = query.slice(1).trim();
        return term.length >= 3 && "windows".startsWith(term);
    }

    function isSystemCommandQuery(rawQuery) {
        const query = String(rawQuery || "").trim().toLocaleLowerCase();

        if (!query.startsWith(">"))
            return false;

        const term = query.slice(1).trim();

        // Keep the command mode restricted to the three fixed host actions.
        // An empty term is useful as a small discoverable command list, while
        // arbitrary input such as >shutdown-now never becomes executable.
        return term.length === 0
            || systemCommandDefinitions.some(
                definition => definition.command.startsWith(term)
            );
    }

    function systemCommandEntries() {
        const query = String(searchInput.text || "")
            .trim()
            .toLocaleLowerCase();
        const term = query.startsWith(">")
            ? query.slice(1).trim()
            : "";

        return systemCommandDefinitions.filter(
            definition => term.length === 0
                || definition.command.startsWith(term)
        );
    }

    function calculatorExpression(rawQuery) {
        const query = String(rawQuery || "").trim();

        if (!query.startsWith(">"))
            return "";

        return query.slice(1)
            .replace(/\s+/g, "")
            .replace(/×/g, "*")
            .replace(/÷/g, "/")
            .replace(/,/g, ".");
    }

    function normalizeInteger(value) {
        let text = String(value || "");
        let negative = false;

        if (text[0] === "-" || text[0] === "+") {
            negative = text[0] === "-";
            text = text.slice(1);
        }

        let firstDigit = 0;

        while (firstDigit < text.length - 1 && text[firstDigit] === "0")
            firstDigit += 1;

        text = text.slice(firstDigit) || "0";

        if (text === "0")
            return "0";

        return negative ? "-" + text : text;
    }

    function integerAbs(value) {
        const text = normalizeInteger(value);
        return text[0] === "-" ? text.slice(1) : text;
    }

    function integerNegative(value) {
        return normalizeInteger(value)[0] === "-";
    }

    function compareIntegerAbs(left, right) {
        const leftAbs = integerAbs(left);
        const rightAbs = integerAbs(right);

        if (leftAbs.length !== rightAbs.length)
            return leftAbs.length < rightAbs.length ? -1 : 1;

        if (leftAbs === rightAbs)
            return 0;

        return leftAbs < rightAbs ? -1 : 1;
    }

    function addIntegerAbs(left, right) {
        let leftIndex = left.length - 1;
        let rightIndex = right.length - 1;
        let carry = 0;
        let result = "";

        while (leftIndex >= 0 || rightIndex >= 0 || carry > 0) {
            const leftDigit = leftIndex >= 0
                ? Number(left[leftIndex--])
                : 0;
            const rightDigit = rightIndex >= 0
                ? Number(right[rightIndex--])
                : 0;
            const sum = leftDigit + rightDigit + carry;

            result = String(sum % 10) + result;
            carry = Math.floor(sum / 10);
        }

        return normalizeInteger(result);
    }

    function subtractIntegerAbs(left, right) {
        // This helper expects |left| >= |right|.
        let leftIndex = left.length - 1;
        let rightIndex = right.length - 1;
        let borrow = 0;
        let result = "";

        while (leftIndex >= 0) {
            let difference = Number(left[leftIndex--]) - borrow;

            if (rightIndex >= 0)
                difference -= Number(right[rightIndex--]);

            if (difference < 0) {
                difference += 10;
                borrow = 1;
            } else {
                borrow = 0;
            }

            result = String(difference) + result;
        }

        return normalizeInteger(result);
    }

    function addInteger(left, right) {
        const leftValue = normalizeInteger(left);
        const rightValue = normalizeInteger(right);
        const leftNegative = integerNegative(leftValue);
        const rightNegative = integerNegative(rightValue);
        const leftAbs = integerAbs(leftValue);
        const rightAbs = integerAbs(rightValue);

        if (leftNegative === rightNegative) {
            const sum = addIntegerAbs(leftAbs, rightAbs);
            return leftNegative && sum !== "0" ? "-" + sum : sum;
        }

        const comparison = compareIntegerAbs(leftAbs, rightAbs);

        if (comparison === 0)
            return "0";

        if (comparison > 0) {
            const difference = subtractIntegerAbs(leftAbs, rightAbs);
            return leftNegative ? "-" + difference : difference;
        }

        const difference = subtractIntegerAbs(rightAbs, leftAbs);
        return rightNegative ? "-" + difference : difference;
    }

    function negateInteger(value) {
        const normalized = normalizeInteger(value);
        return normalized === "0"
            ? "0"
            : integerNegative(normalized)
            ? normalized.slice(1)
            : "-" + normalized;
    }

    function multiplyInteger(left, right) {
        const leftValue = normalizeInteger(left);
        const rightValue = normalizeInteger(right);
        const leftAbs = integerAbs(leftValue);
        const rightAbs = integerAbs(rightValue);

        if (leftAbs === "0" || rightAbs === "0")
            return "0";

        const digits = [];

        for (let index = 0; index < leftAbs.length + rightAbs.length; index += 1)
            digits.push(0);

        for (let leftIndex = leftAbs.length - 1;
                leftIndex >= 0;
                leftIndex -= 1) {
            let carry = 0;

            for (let rightIndex = rightAbs.length - 1;
                    rightIndex >= 0;
                    rightIndex -= 1) {
                const index = leftIndex + rightIndex + 1;
                const product = Number(leftAbs[leftIndex])
                    * Number(rightAbs[rightIndex])
                    + digits[index]
                    + carry;

                digits[index] = product % 10;
                carry = Math.floor(product / 10);
            }

            digits[leftIndex] += carry;
        }

        const product = normalizeInteger(digits.join(""));
        return integerNegative(leftValue) !== integerNegative(rightValue)
            ? "-" + product
            : product;
    }

    function divideIntegerAbs(dividend, divisor) {
        const normalizedDivisor = normalizeInteger(divisor);

        if (normalizedDivisor === "0")
            return null;

        let quotient = "";
        let remainder = "0";

        for (let index = 0; index < dividend.length; index += 1) {
            remainder = normalizeInteger(
                remainder === "0"
                    ? dividend[index]
                    : remainder + dividend[index]
            );

            let quotientDigit = 0;

            while (compareIntegerAbs(remainder, normalizedDivisor) >= 0) {
                remainder = subtractIntegerAbs(
                    remainder,
                    normalizedDivisor
                );
                quotientDigit += 1;
            }

            quotient += String(quotientDigit);
        }

        return {
            quotient: normalizeInteger(quotient),
            remainder: normalizeInteger(remainder)
        };
    }

    function divideInteger(left, right) {
        const leftValue = normalizeInteger(left);
        const rightValue = normalizeInteger(right);
        const division = divideIntegerAbs(
            integerAbs(leftValue),
            integerAbs(rightValue)
        );

        if (division === null)
            return null;

        const quotient = division.quotient === "0"
            || integerNegative(leftValue) === integerNegative(rightValue)
            ? division.quotient
            : "-" + division.quotient;
        const remainder = integerNegative(leftValue)
            && division.remainder !== "0"
            ? "-" + division.remainder
            : division.remainder;

        return { quotient: quotient, remainder: remainder };
    }

    function powerInteger(base, exponent) {
        const exponentNumber = Number(exponent);

        if (integerNegative(exponent)
                || !isFinite(exponentNumber)
                || exponentNumber < 0
                || exponentNumber > 1000
                || Math.floor(exponentNumber) !== exponentNumber)
            return null;

        let result = "1";
        let factor = normalizeInteger(base);
        let remaining = exponentNumber;

        while (remaining > 0) {
            if (remaining % 2 === 1)
                result = multiplyInteger(result, factor);

            remaining = Math.floor(remaining / 2);

            if (remaining > 0)
                factor = multiplyInteger(factor, factor);
        }

        return result;
    }

    function calculateIntegerExpression(rawQuery) {
        const expression = calculatorExpression(rawQuery);

        if (expression.length === 0
                || expression.length > 80
                || !/^[0-9.+\-*/%^()]+$/.test(expression)
                || expression.indexOf(".") >= 0)
            return null;

        let cursor = 0;

        function parseNumber() {
            const match = expression.slice(cursor).match(/^\d+/);

            if (!match)
                return null;

            cursor += match[0].length;
            return normalizeInteger(match[0]);
        }

        function parsePrimary() {
            if (expression[cursor] === "(") {
                cursor += 1;
                const value = parseAddSub();

                if (value === null || expression[cursor] !== ")")
                    return null;

                cursor += 1;
                return value;
            }

            return parseNumber();
        }

        function parsePower() {
            const value = parsePrimary();

            if (value === null)
                return null;

            if (expression[cursor] !== "^")
                return value;

            cursor += 1;
            const exponent = parseUnary();

            if (exponent === null)
                return null;

            return powerInteger(value, exponent);
        }

        function parseUnary() {
            const operator = expression[cursor];

            if (operator === "+" || operator === "-") {
                cursor += 1;
                const value = parseUnary();

                if (value === null)
                    return null;

                return operator === "-" ? negateInteger(value) : value;
            }

            return parsePower();
        }

        function parseMultiplyDivide() {
            let value = parseUnary();

            if (value === null)
                return null;

            while (expression[cursor] === "*"
                    || expression[cursor] === "/"
                    || expression[cursor] === "%") {
                const operator = expression[cursor++];
                const right = parseUnary();

                if (right === null)
                    return null;

                if (operator === "*") {
                    value = multiplyInteger(value, right);
                } else {
                    const division = divideInteger(value, right);

                    if (division === null)
                        return null;

                    if (operator === "/") {
                        // Let the decimal parser handle non-integer division.
                        if (division.remainder !== "0")
                            return null;

                        value = division.quotient;
                    } else {
                        value = division.remainder;
                    }
                }
            }

            return value;
        }

        function parseAddSub() {
            let value = parseMultiplyDivide();

            if (value === null)
                return null;

            while (expression[cursor] === "+"
                    || expression[cursor] === "-") {
                const operator = expression[cursor++];
                const right = parseMultiplyDivide();

                if (right === null)
                    return null;

                value = operator === "+"
                    ? addInteger(value, right)
                    : addInteger(value, negateInteger(right));
            }

            return value;
        }

        const result = parseAddSub();

        return result !== null && cursor === expression.length
            ? result
            : null;
    }

    function calculateExpression(rawQuery) {
        const expression = calculatorExpression(rawQuery);

        if (expression.length === 0
                || expression.length > 80
                || !/^[0-9.+\-*/%^()]+$/.test(expression))
            return null;

        let cursor = 0;

        function parseNumber() {
            const match = expression.slice(cursor).match(
                /^(?:\d+(?:\.\d*)?|\.\d+)/
            );

            if (!match)
                return null;

            cursor += match[0].length;
            const value = Number(match[0]);
            return isFinite(value) ? value : null;
        }

        function parsePrimary() {
            if (expression[cursor] === "(") {
                cursor += 1;
                const value = parseAddSub();

                if (value === null || expression[cursor] !== ")")
                    return null;

                cursor += 1;
                return value;
            }

            return parseNumber();
        }

        function parsePower() {
            const value = parsePrimary();

            if (value === null)
                return null;

            if (expression[cursor] !== "^")
                return value;

            cursor += 1;
            const exponent = parseUnary();

            if (exponent === null)
                return null;

            const powered = Math.pow(value, exponent);
            return isFinite(powered) ? powered : null;
        }

        function parseUnary() {
            const operator = expression[cursor];

            if (operator === "+" || operator === "-") {
                cursor += 1;
                const value = parseUnary();

                if (value === null)
                    return null;

                return operator === "-" ? -value : value;
            }

            return parsePower();
        }

        function parseMultiplyDivide() {
            let value = parseUnary();

            if (value === null)
                return null;

            while (expression[cursor] === "*"
                    || expression[cursor] === "/"
                    || expression[cursor] === "%") {
                const operator = expression[cursor++];
                const right = parseUnary();

                if (right === null
                        || ((operator === "/" || operator === "%")
                            && right === 0))
                    return null;

                if (operator === "*")
                    value *= right;
                else if (operator === "/")
                    value /= right;
                else
                    value %= right;

                if (!isFinite(value))
                    return null;
            }

            return value;
        }

        function parseAddSub() {
            let value = parseMultiplyDivide();

            if (value === null)
                return null;

            while (expression[cursor] === "+"
                    || expression[cursor] === "-") {
                const operator = expression[cursor++];
                const right = parseMultiplyDivide();

                if (right === null)
                    return null;

                value = operator === "+"
                    ? value + right
                    : value - right;

                if (!isFinite(value))
                    return null;
            }

            return value;
        }

        const result = parseAddSub();

        if (result === null || cursor !== expression.length)
            return null;

        return isFinite(result) ? result : null;
    }

    function isCalculatorQuery(rawQuery) {
        const query = String(rawQuery || "").trim();

        if (!query.startsWith(">")
                || isVirtualMachineQuery(query)
                || isSystemCommandQuery(query))
            return false;

        return calculateIntegerExpression(query) !== null
            || calculateExpression(query) !== null;
    }

    function calculatorEntries() {
        const exactValue = calculateIntegerExpression(searchInput.text);

        if (exactValue !== null) {
            return [{
                name: exactValue,
                calculator: true,
                glyph: "\uf52c"
            }];
        }

        const value = calculateExpression(searchInput.text);

        if (value === null)
            return [];

        return [{
            name: formatCalculatorResult(value),
            calculator: true,
            glyph: "\uf52c"
        }];
    }

    function formatCalculatorResult(value) {
        if (!isFinite(value))
            return "";

        // Keep ordinary decimal calculations readable while retaining the
        // full finite value for large results. Expand scientific notation so
        // the launcher never shows an e+ exponent in the result row.
        const normalized = Math.abs(value) < 1e21
            ? Number(value.toPrecision(15))
            : value;
        return expandScientificNotation(String(normalized));
    }

    function expandScientificNotation(value) {
        const text = String(value).toLocaleLowerCase();
        const exponentMarker = text.indexOf("e");

        if (exponentMarker < 0)
            return text;

        const exponent = Number(text.slice(exponentMarker + 1));

        if (!isFinite(exponent))
            return text;

        let coefficient = text.slice(0, exponentMarker);
        let sign = "";

        if (coefficient[0] === "-" || coefficient[0] === "+") {
            sign = coefficient[0] === "-" ? "-" : "";
            coefficient = coefficient.slice(1);
        }

        const decimalPoint = coefficient.indexOf(".");
        const integerDigits = decimalPoint < 0
            ? coefficient.length
            : decimalPoint;
        const digits = coefficient.replace(".", "");
        const decimalPosition = integerDigits + exponent;

        function zeros(count) {
            let result = "";

            for (let index = 0; index < count; index += 1)
                result += "0";

            return result;
        }

        if (decimalPosition <= 0)
            return sign + "0." + zeros(-decimalPosition) + digits;

        if (decimalPosition >= digits.length)
            return sign + digits + zeros(decimalPosition - digits.length);

        return sign
            + digits.slice(0, decimalPosition)
            + "."
            + digits.slice(decimalPosition);
    }

    function virtualMachineStateIcon(state) {
        const normalized = String(state || "unknown").trim().toLocaleLowerCase();

        if (normalized === "running"
                || normalized === "blocked"
                || normalized === "nostate")
            return "state_running.png";
        if (normalized === "paused" || normalized === "pmsuspended")
            return "state_paused.png";

        return "state_shutoff.png";
    }

    function virtualMachineIconPath(entry) {
        // virt-manager's manager view asks GTK for state_* status icons.  The
        // VM helper resolves the active GTK theme path for every refresh, so
        // this uses the same Papirus-Dark artwork as the native VMM list.
        const installedIconPath = String(entry && entry.iconPath || "")
            .trim();

        if (installedIconPath.length > 0)
            return "file://" + installedIconPath;

        return "file://" + Quickshell.shellPath(
            "assets/virtual-machines/" + virtualMachineStateIcon(entry.state)
        );
    }

    function virtualMachineIsRunning(entry) {
        return String(entry && entry.state || "")
            .trim()
            .toLocaleLowerCase() === "running";
    }

    function refreshVirtualMachines() {
        if (!virtualMachineQueryMode || vmListProcess.running)
            return;

        vmListProcess.running = true;
    }

    function updateVirtualMachines(rawText) {
        const entries = [];

        for (const line of String(rawText || "").split("\n")) {
            const fields = line.trim().split("\t");
            const name = fields[0] || "";

            if (name.length === 0)
                continue;

            entries.push({
                name: name,
                state: fields[1] || "unknown",
                iconPath: fields[2] || "",
                icon: "computer"
            });
        }

        virtualMachineEntries = entries;
    }

    function papirusApplicationIconPath(entry) {
        const icon = entry.icon || "";

        if (!/^[A-Za-z0-9._+-]+$/.test(icon))
            return "";

        return "/etc/profiles/per-user/user/share/icons/"
            + "Papirus/64x64/apps/" + icon + ".svg";
    }

    function multiContainsScore(entry, tokens) {
        const haystack = searchableText(entry);
        let score = 0;

        for (const token of tokens) {
            const position = haystack.indexOf(token);

            if (position < 0)
                return -1;

            score += position;
        }

        return score;
    }

    function searchApplications() {
        const query = searchInput.text.trim().toLocaleLowerCase();

        if (query.length === 0)
            return [];

        const tokens = query.split(/\s+/).filter(token => token.length > 0);

        return DesktopEntries.applications.values
            .filter(entry => !entry.noDisplay)
            .map((entry, order) => {
                const name = (entry.name || "").toLocaleLowerCase();

                return {
                    entry: entry,
                    order: order,
                    score: multiContainsScore(entry, tokens),
                    exactName: name === query ? 0 : 1,
                    namePrefix: name.startsWith(query) ? 0 : 1,
                    nameLength: name.length
                };
            })
            .filter(candidate => candidate.score >= 0)
            .sort((left, right) =>
                left.exactName - right.exactName
                    || left.namePrefix - right.namePrefix
                    || left.score - right.score
                    || left.nameLength - right.nameLength
                    || left.order - right.order)
            .slice(0, 3)
            .map(candidate => candidate.entry);
    }

    function launchResult(index) {
        if (index < 0 || index >= results.length)
            return;

        const entry = results[index];

        if (virtualMachineShutdownMode) {
            if (entry.action === "shutdown")
                confirmVirtualMachineShutdown();
            else if (entry.action === "forceShutdown")
                forceVirtualMachineShutdown();
            else
                cancelVirtualMachineShutdown();
            return;
        }

        if (systemCommandMode) {
            launchSystemCommand(entry.command);
            return;
        }

        if (calculatorMode)
            return;

        if (virtualMachineQueryMode) {
            if (virtualMachineIsRunning(entry)) {
                requestVirtualMachineShutdown(entry);
                return;
            }

            Quickshell.execDetached([
                "bash",
                Quickshell.shellPath("scripts/start-virtual-machine.sh"),
                entry.name
            ]);
            requestClose();
            return;
        }

        // Steam's split-tunnel desktop entry starts a second process even when
        // the client already exists. Focus that window first. On a fresh start,
        // prefer Mullvad's wrapper and fall back to Steam if the local cgroup
        // permission currently prevents mullvad-exclude from launching it.
        if (entry.id === "mullvad-excluded-steam") {
            Quickshell.execDetached([
                "bash",
                "-lc",
                "if hyprctl repl 'for _,w in pairs(hl.get_windows()) "
                    + "do if w.class == \"steam\" then print(\"yes\") "
                    + "end end' | grep -qx yes; then "
                    + "exec hyprctl dispatch 'hl.dsp.focus({ "
                    + "window = \"class:^steam$\" })'; "
                    + "else mullvad-exclude steam || exec steam; fi"
            ]);
        } else {
            entry.execute();
        }

        requestClose();
    }

    function launchSystemCommand(command) {
        const allowed = systemCommandDefinitions.some(
            definition => definition.command === command
        );

        if (!allowed)
            return;

        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("scripts/system-command.sh"),
            command
        ]);
        requestClose();
    }

    function requestVirtualMachineShutdown(entry) {
        virtualMachineQueryText = searchInput.text;
        virtualMachineConfirmationEntry = entry;
        searchInput.text = "Shut down " + entry.name + "?";
        searchInput.cursorPosition = 0;
        selectedIndex = 0;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function cancelVirtualMachineShutdown() {
        const query = virtualMachineQueryText || ">Win";

        virtualMachineConfirmationEntry = null;
        virtualMachineQueryText = "";
        searchInput.text = query;
        searchInput.cursorPosition = searchInput.length;
        selectedIndex = 0;
        refreshVirtualMachines();
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function confirmVirtualMachineShutdown() {
        const entry = virtualMachineConfirmationEntry;

        if (!entry)
            return;

        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("scripts/shutdown-virtual-machine.sh"),
            entry.name
        ]);
        virtualMachineConfirmationEntry = null;
        requestClose();
    }

    function forceVirtualMachineShutdown() {
        const entry = virtualMachineConfirmationEntry;

        if (!entry)
            return;

        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("scripts/shutdown-virtual-machine.sh"),
            "--force",
            entry.name
        ]);
        virtualMachineConfirmationEntry = null;
        requestClose();
    }

    function requestOpen() {
        if (openRequested && surfaceVisible)
            return;

        openRequested = true;
        surfaceVisible = true;
        dismissalCaptureActive = true;
        keyboardActive = true;
        edgeCloseArmed = false;
        edgeClosePrimed = false;
        Qt.callLater(() => searchInput.forceActiveFocus());
        slideAnimation.stop();
        slideAnimation.from = surfaceY;
        slideAnimation.to = visibleY;
        slideAnimation.start();
    }

    function requestClose() {
        if (!surfaceVisible || !openRequested)
            return;

        openRequested = false;
        dismissalCaptureActive = false;
        keyboardActive = false;
        edgeCloseArmed = false;
        edgeClosePrimed = false;
        searchInput.focus = false;
        slideAnimation.stop();
        slideAnimation.from = surfaceY;
        slideAnimation.to = hiddenY;
        slideAnimation.start();
    }

    // The transparent dismissal surface consumes the pointer event, so the
    // compositor never gets a chance to focus the window underneath it. Find
    // the mapped Hyprland window at the current pointer position and explicitly
    // restore focus after closing the launcher. This keeps dismissal monitor-
    // agnostic and works for windows on a different workspace as well.
    function focusWindowUnderCursor() {
        const script = [
            "local p=hl.get_cursor_pos()",
            "local m=hl.get_monitor_at_cursor()",
            "local target=nil",
            "for _,w in pairs(hl.get_windows()) do",
            "if w.mapped and not w.hidden and w.monitor.id == m.id",
            "and w.workspace.id == m.active_workspace.id and",
            "p.x >= w.at.x and p.y >= w.at.y and",
            "p.x < w.at.x+w.size.x and p.y < w.at.y+w.size.y then",
            "target=w end end",
            "if target then",
            "hl.dispatch(hl.dsp.focus({ monitor = target.monitor }))",
            "hl.dispatch(hl.dsp.focus({ workspace = target.workspace }))",
            "hl.dispatch(hl.dsp.focus({ window = target }))",
            // Focusing a window can make Hyprland warp the pointer to that
            // window's center. Restore the exact pre-dismissal coordinates so
            // clicking away only closes the launcher and never moves the
            // user's cursor.
            "hl.dispatch(hl.dsp.cursor.move({ x = p.x, y = p.y }))",
            "end"
        ].join(" ");

        Quickshell.execDetached(["hyprctl", "eval", script]);
    }

    function dismissFromPointer() {
        requestClose();
        focusWindowUnderCursor();
    }

    // The cross-monitor dismissal layer needs exclusive keyboard focus so it
    // can receive ESC. When that layer owns the seat, forward normal editing
    // keys to the real TextInput so opening the launcher remains keyboard-first
    // even if the pointer is currently on another monitor.
    function handleExternalKey(key, text, modifiers) {
        if (!surfaceVisible || !openRequested)
            return false;

        if (key === Qt.Key_Escape) {
            if (virtualMachineShutdownMode)
                cancelVirtualMachineShutdown();
            else
                requestClose();
            return true;
        }

        if (key === Qt.Key_Down && results.length > 0) {
            selectedIndex = (selectedIndex + 1) % results.length;
            return true;
        }

        if (key === Qt.Key_Up && results.length > 0) {
            selectedIndex =
                (selectedIndex + results.length - 1) % results.length;
            return true;
        }

        if ((key === Qt.Key_Return || key === Qt.Key_Enter)
                && results.length > 0) {
            launchResult(selectedIndex);
            return true;
        }

        if (virtualMachineShutdownMode)
            return true;

        if (key === Qt.Key_Backspace) {
            if (searchInput.cursorPosition > 0) {
                searchInput.remove(
                    searchInput.cursorPosition - 1,
                    searchInput.cursorPosition
                );
            }
            return true;
        }

        if (key === Qt.Key_Delete) {
            searchInput.remove(
                searchInput.cursorPosition,
                searchInput.cursorPosition + 1
            );
            return true;
        }

        if (key === Qt.Key_Left) {
            searchInput.cursorPosition =
                Math.max(0, searchInput.cursorPosition - 1);
            return true;
        }

        if (key === Qt.Key_Right) {
            searchInput.cursorPosition =
                Math.min(searchInput.length, searchInput.cursorPosition + 1);
            return true;
        }

        const navigationModifiers = Qt.ControlModifier
            | Qt.AltModifier
            | Qt.MetaModifier;

        if (text && !(modifiers & navigationModifiers)) {
            const remaining = searchInput.maximumLength
                - searchInput.length;
            const insertion = String(text).slice(
                0,
                Math.max(0, remaining)
            );

            if (insertion.length > 0) {
                searchInput.insert(searchInput.cursorPosition, insertion);
                searchInput.cursorPosition += insertion.length;
            }
            return true;
        }

        return false;
    }

    anchors.fill: parent

    onResultsChanged: selectedIndex = 0

    onVirtualMachineModeChanged: {
        virtualMachineEntries = [];
        if (virtualMachineQueryMode)
            refreshVirtualMachines();
    }

    onSurfaceVisibleChanged: {
        if (surfaceVisible && virtualMachineQueryMode)
            refreshVirtualMachines();
    }

    onPointerInsideChanged: {
        if (pointerInside)
            requestOpen();
    }

    Item {
        id: activationZone

        x: root.surfaceX
        y: 0
        width: root.surfaceWidth
        height: root.borderThickness

        HoverHandler {
            id: activationHover

            onPointChanged: {
                if (!root.edgeCloseArmed)
                    return;

                if (!activationHover.hovered) {
                    root.edgeClosePrimed = true;
                    return;
                }

                if (point.position.y > 1) {
                    root.edgeClosePrimed = true;
                } else if (root.edgeClosePrimed) {
                    root.requestClose();
                }
            }

            onHoveredChanged: {
                if (root.edgeCloseArmed && !hovered)
                    root.edgeClosePrimed = true;
            }
        }
    }

    Item {
        id: panelInteraction

        visible: root.surfaceVisible
        x: root.surfaceX
        y: root.surfaceY
        width: root.surfaceWidth
        height: root.surfaceHeight

        HoverHandler {
            id: panelHover
        }
    }

    // While opened from the keyboard, make the rest of the desktop a click-to-
    // dismiss surface. This region is below the visible panel, so clicks on
    // search/results continue to be handled by their own controls.
    Item {
        id: dismissalZone

        visible: root.surfaceVisible
        anchors.fill: parent
        z: 1

        // Keep the capture areas disjoint from the visible launcher surface.
        // A single full-screen MouseArea would also eat clicks and text input
        // inside the search/results panel; four surrounding regions provide
        // the same click-to-dismiss behavior without stealing those events.
        MouseArea {
            x: 0
            y: 0
            width: parent.width
            height: Math.max(0, root.surfaceY)
            acceptedButtons: Qt.LeftButton
            onClicked: root.dismissFromPointer()
        }

        MouseArea {
            x: 0
            y: root.surfaceY
            width: Math.max(0, root.surfaceX)
            height: root.surfaceHeight
            acceptedButtons: Qt.LeftButton
            onClicked: root.dismissFromPointer()
        }

        MouseArea {
            x: root.surfaceX + root.surfaceWidth
            y: root.surfaceY
            width: Math.max(0, parent.width - x)
            height: root.surfaceHeight
            acceptedButtons: Qt.LeftButton
            onClicked: root.dismissFromPointer()
        }

        MouseArea {
            x: 0
            y: root.surfaceY + root.surfaceHeight
            width: parent.width
            height: Math.max(0, parent.height - y)
            acceptedButtons: Qt.LeftButton
            onClicked: root.dismissFromPointer()
        }
    }

    Item {
        id: contentClip

        x: 0
        y: root.borderThickness
        width: root.width
        height: root.height - y
        clip: true
        z: 2

        Item {
            id: panelContent

            x: root.surfaceX
            y: root.surfaceY - contentClip.y
            width: root.surfaceWidth
            height: root.surfaceHeight
            clip: true

            Rectangle {
                id: searchField

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: root.surfaceInset
                }

                height: 40
                radius: root.searchCornerRadius
                color: Theme.launcherField
                antialiasing: true

                Text {
                    visible: searchInput.text.length === 0
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }

                    text: "Start typing..."
                    color: Theme.launcherPlaceholder
                    font {
                        family: "Iosevka"
                        pixelSize: 16
                    }
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                TextInput {
                    id: searchInput

                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }

                    color: Theme.launcherText
                    selectionColor: Theme.launcherSelection
                    selectedTextColor: Theme.launcherSelectedText
                    maximumLength: root.searchMaximumLength
                    readOnly: root.virtualMachineShutdownMode
                    clip: true
                    cursorDelegate: Item {
                        width: 0
                        visible: false
                    }
                    font {
                        family: "Iosevka"
                        pixelSize: 16
                    }
                    verticalAlignment: TextInput.AlignVCenter

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            if (root.virtualMachineShutdownMode)
                                root.cancelVirtualMachineShutdown();
                            else
                                root.requestClose();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down
                                && root.results.length > 0) {
                            root.selectedIndex =
                                (root.selectedIndex + 1)
                                % root.results.length;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up
                                && root.results.length > 0) {
                            root.selectedIndex =
                                (root.selectedIndex
                                    + root.results.length - 1)
                                % root.results.length;
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_Return
                                    || event.key === Qt.Key_Enter)
                                && root.results.length > 0) {
                            root.launchResult(root.selectedIndex);
                            event.accepted = true;
                        }
                    }
                }
            }

            Column {
                id: resultColumn

                x: root.surfaceInset
                y: 64
                width: parent.width - 2 * root.surfaceInset
                spacing: root.resultRowStep - root.resultRowHeight

                Repeater {
                    model: ScriptModel {
                        values: root.results
                    }

                    Item {
                        id: resultRow

                        required property var modelData
                        required property int index

                        width: resultColumn.width
                        height: root.resultRowHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: root.searchCornerRadius
                            color: resultMouse.containsMouse
                                    || root.selectedIndex === resultRow.index
                                ? Theme.launcherResultHover
                                : Theme.transparent
                            antialiasing: true
                        }

                        Item {
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            width: 28
                            height: 28

                            FileView {
                                id: papirusIconFile

                                property string readyPath: ""

                                path: root.virtualMachineMode
                                    || root.systemCommandMode
                                    || root.calculatorMode
                                    ? ""
                                    : root.papirusApplicationIconPath(
                                        resultRow.modelData
                                    )
                                preload: true
                                printErrors: false
                                onPathChanged: readyPath = ""
                                onLoaded: readyPath = path
                                onLoadFailed: readyPath = ""
                            }

                            IconImage {
                                visible: !root.virtualMachineMode
                                    && !root.systemCommandMode
                                    && !root.calculatorMode
                                anchors.fill: parent
                                source: root.virtualMachineMode
                                    || root.systemCommandMode
                                    || root.calculatorMode
                                    ? ""
                                    : papirusIconFile.readyPath !== ""
                                    ? "file://" + papirusIconFile.readyPath
                                    : root.applicationIcon(
                                        resultRow.modelData
                                    )
                                mipmap: false
                            }

                            Text {
                                visible: root.systemCommandMode
                                    || root.calculatorMode
                                anchors.fill: parent
                                text: resultRow.modelData.glyph || ""
                                color: Theme.launcherText
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font {
                                    family: "Font Awesome 7 Free"
                                    styleName: "Solid"
                                    pixelSize: 16
                                }
                            }

                            // These are the same 32px GTK status icons resolved
                            // by virt-manager: shutoff, running, and paused.
                            Image {
                                visible: root.virtualMachineQueryMode
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                source: root.virtualMachineIconPath(
                                    resultRow.modelData
                                )
                                fillMode: Image.PreserveAspectFit
                                smooth: false
                                mipmap: false
                            }
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: root.virtualMachineShutdownMode ? 12 : 50
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }

                            text: resultRow.modelData.name
                            color: Theme.launcherText
                            font {
                                family: "Iosevka"
                                pixelSize: root.calculatorMode
                                    ? Math.max(
                                        10,
                                        Math.min(
                                            15,
                                            width
                                                / Math.max(
                                                    1,
                                                    text.length
                                                )
                                                * 1.9
                                        )
                                    )
                                    : 15
                                weight: Font.Medium
                            }
                            elide: root.calculatorMode
                                ? Text.ElideNone
                                : Text.ElideRight
                            clip: root.calculatorMode
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: resultMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = resultRow.index
                            onClicked: root.launchResult(resultRow.index)
                        }
                    }
                }
            }
        }
    }

    NumberAnimation {
        id: slideAnimation

        target: root
        property: "surfaceY"
        duration: 280
        easing.type: Easing.OutBack
        easing.overshoot: 1.15
        onFinished: {
            if (root.openRequested) {
                root.edgeCloseArmed = true;
                root.edgeClosePrimed = !activationHover.hovered
                    || activationHover.point.position.y > 1;
                Qt.callLater(() => searchInput.forceActiveFocus());
            } else {
                root.surfaceY = root.hiddenY;
                root.surfaceVisible = false;
                root.edgeCloseArmed = false;
                root.edgeClosePrimed = false;
                searchInput.clear();
                root.virtualMachineConfirmationEntry = null;
                root.virtualMachineQueryText = "";
            }
        }
    }

    Behavior on surfaceHeight {
        enabled: root.surfaceVisible

        NumberAnimation {
            duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    Process {
        id: vmListProcess

        command: [
            "bash",
            Quickshell.shellPath("scripts/virtual-machines.sh")
        ]

        stdout: StdioCollector {
            onStreamFinished: root.updateVirtualMachines(text)
        }

        stderr: StdioCollector {}
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.surfaceVisible && root.virtualMachineQueryMode
        onTriggered: root.refreshVirtualMachines()
    }
}
