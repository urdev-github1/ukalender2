// Importiert das 'fs'-Modul für Dateisystemoperationen (z.B. Lesen/Schreiben von Dateien, Überprüfen von Verzeichnissen).
const fs = require('fs');
// Importiert das 'path'-Modul für die Arbeit mit Dateipfaden (z.B. Join, Relative, Extname).
const path = require('path');

// ===============================================
//           KONFIGURATION
// ===============================================

// Definiert den Namen der Ausgabedatei, in die die generierten Inhalte geschrieben werden.
const outputFile = 'dart_export.txt';
// Schalter zur Steuerung der Zeilennummern: true = mit Zeilennummern, false = ohne Zeilennummern.
const includeLineNumbers = true; // <-- HIER KANN DER SCHALTER UMGESCHALTET WERDEN

// ===============================================
//           GLOBALE VARIABLEN UND PFADE
// ===============================================

// Ermittelt das aktuelle Arbeitsverzeichnis des Prozesses, welches als Wurzelverzeichnis des Projekts angenommen wird.
const projectRoot = process.cwd();
// Erstellt den vollständigen Pfad zum 'lib'-Verzeichnis innerhalb des Projektwurzelverzeichnisses.
const libDir = path.join(projectRoot, 'lib');

// Liste der Dateien, die vom Export ausgeschlossen werden sollen.
// Die Pfade sind relativ zum Projektverzeichnis angegeben.
const excludedFiles = [
    'lib/generated/build_info.dart',
    'lib/build_info.dart',
    'lib/firebase_options.dart',
    'lib/models/event.g.dart',
    '.dart_tool/flutter_build/dart_plugin_registrant.dart'
].map(file => path.normalize(file)); // Normalisiert jeden Pfad in der Liste für plattformübergreifende Konsistenz.

// ===============================================
//           HILFSFUNKTIONEN
// ===============================================

/**
 * Überprüft, ob eine gegebene Datei basierend auf der 'excludedFiles'-Liste ausgeschlossen werden soll.
 * @param {string} filePath Der vollständige Pfad der zu überprüfenden Datei.
 * @returns {boolean} True, wenn die Datei ausgeschlossen werden soll, sonst False.
 */
function shouldExclude(filePath) {
    // Erzeugt den relativen Pfad der Datei zum Projektwurzelverzeichnis.
    const relativePath = path.relative(projectRoot, filePath);
    // Überprüft, ob dieser relative Pfad in der Liste der ausgeschlossenen Dateien enthalten ist.
    return excludedFiles.includes(relativePath);
}

/**
 * Generiert eine ASCII-Baumstruktur eines Verzeichnisses.
 * Berücksichtigt nur Verzeichnisse und nicht ausgeschlossene .dart-Dateien.
 * @param {string} dir Das Verzeichnis, dessen Baumstruktur generiert werden soll.
 * @param {string} prefix Der Präfix für die aktuelle Ebene (für Einrückung und Linien).
 * @param {boolean} isLast Gibt an, ob das aktuelle Verzeichnis/Element das letzte in seiner übergeordneten Liste ist.
 * @returns {string} Die generierte Baumstruktur als Zeichenkette.
 */
function generateDirectoryTree(dir, prefix = '', isLast = true) {
    let tree = '';
    // Liest den Inhalt des Verzeichnisses und gibt FileType-Informationen zurück.
    const items = fs.readdirSync(dir, { withFileTypes: true });

    // Filtert die Elemente: Nur Verzeichnisse oder .dart-Dateien, die nicht ausgeschlossen sind.
    const filteredItems = items.filter(item => {
        const fullPath = path.join(dir, item.name);
        if (item.isDirectory()) return true;
        return path.extname(fullPath) === '.dart' && !shouldExclude(fullPath);
    });

    // Sortiert die gefilterten Elemente: zuerst Verzeichnisse, dann Dateien, alphabetisch.
    filteredItems.sort((a, b) => {
        if (a.isDirectory() && !b.isDirectory()) return -1;
        if (!a.isDirectory() && b.isDirectory()) return 1;
        return a.name.localeCompare(b.name);
    });

    for (let i = 0; i < filteredItems.length; i++) {
        const item = filteredItems[i];
        const fullPath = path.join(dir, item.name);
        const isLastItem = i === filteredItems.length - 1;

        if (item.isDirectory()) {
            tree += `${prefix}${isLast ? '└── ' : '├── '}${item.name}/\n`;
            tree += generateDirectoryTree(
                fullPath,
                `${prefix}${isLast ? '    ' : '│   '}`,
                isLastItem
            );
        } else {
            tree += `${prefix}${isLastItem ? '└── ' : '├── '}${item.name}\n`;
        }
    }

    return tree;
}

/**
 * Fügt Zeilennummern zum Inhalt einer Datei hinzu.
 * @param {string} content Der ursprüngliche Inhalt der Datei.
 * @returns {string} Der Inhalt mit vorangestellten Zeilennummern.
 */
function addLineNumbers(content) {
    const lines = content.split('\n');
    const maxLineNumberLength = String(lines.length).length;

    return lines.map((line, index) => {
        const lineNumber = (index + 1).toString().padStart(maxLineNumberLength, ' ');
        return `${lineNumber}: ${line}`;
    }).join('\n');
}

/**
 * Verarbeitet ein Verzeichnis rekursiv, um den Inhalt aller nicht ausgeschlossenen .dart-Dateien zu extrahieren.
 * Wendet Zeilennummern an, falls 'includeLineNumbers' auf true gesetzt ist.
 * @param {string} dir Das zu verarbeitende Verzeichnis.
 * @returns {string} Der kombinierte Inhalt aller verarbeiteten .dart-Dateien.
 */
function processDirectory(dir) {
    let content = '';
    const items = fs.readdirSync(dir, { withFileTypes: true });

    // Sortiert die Elemente: zuerst Verzeichnisse, dann Dateien, alphabetisch.
    items.sort((a, b) => {
        if (a.isDirectory() && !b.isDirectory()) return -1;
        if (!a.isDirectory() && b.isDirectory()) return 1;
        return a.name.localeCompare(b.name);
    });

    // Durchläuft jedes Element im Verzeichnis.
    for (const item of items) {
        const fullPath = path.join(dir, item.name);

        // Wenn das Element ein Verzeichnis ist, wird es rekursiv verarbeitet.
        if (item.isDirectory()) {
            content += processDirectory(fullPath);
        } else if (path.extname(fullPath) === '.dart' && !shouldExclude(fullPath)) {
            const relativePath = path.relative(projectRoot, fullPath);
            const fileContent = fs.readFileSync(fullPath, 'utf8');
            // Initialisiert den finalen Inhalt der Datei.
            let finalContent = fileContent;
            // Wende Zeilennummern an, wenn der Schalter 'includeLineNumbers' auf true steht.
            if (includeLineNumbers) {
                finalContent = addLineNumbers(fileContent);
            }

            // Fügt eine Überschrift mit dem relativen Pfad der Datei hinzu.
            content += `\n// ==== ${relativePath} ====\n\n`;
            // Fügt den (ggf. nummerierten) Dateiinhalt hinzu.
            content += finalContent;
            content += '\n'; // Fügt eine Leerzeile am Ende der Datei hinzu.
        }
    }

    return content;
}

// ===============================================
//           HAUPTAUSFÜHRUNGSBLOCK
// ===============================================

if (fs.existsSync(libDir)) {
    // Generiert die Verzeichnisbaumstruktur des 'lib'-Ordners.
    const directoryTree = generateDirectoryTree(libDir);

    // Generiert den kombinierten Inhalt aller relevanten .dart-Dateien.
    const exportContent = processDirectory(libDir);

    // Kombiniert die Verzeichnisstruktur und die Dateiinhalte in einem einzigen String.
    const combinedContent = `Verzeichnisstruktur des lib-Ordners:\n\n${directoryTree}\n\n${'='.repeat(80)}\n\nDateiinhalte:\n${exportContent}`;

    // Schreibt den gesamten kombinierten Inhalt in die Ausgabedatei.
    fs.writeFileSync(outputFile, combinedContent, 'utf8');
    console.log(`Verzeichnisstruktur und Dateiinhalte wurden in ${outputFile} exportiert.`);
} else {
    console.error('Das lib-Verzeichnis wurde nicht gefunden!');
}
