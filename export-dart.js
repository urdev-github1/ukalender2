const fs = require('fs');
const path = require('path');

const outputFile = 'dart_export.txt';
const projectRoot = process.cwd();
const libDir = path.join(projectRoot, 'lib');

// Liste der auszuschließenden Dateien (relativ zum Projektverzeichnis)
const excludedFiles = [
    'lib/generated/build_info.dart',
    'lib/build_info.dart',
    'lib/firebase_options.dart',
    'lib/models/event.g.dart',
    '.dart_tool/flutter_build/dart_plugin_registrant.dart'
].map(file => path.normalize(file));

function shouldExclude(filePath) {
    const relativePath = path.relative(projectRoot, filePath);
    return excludedFiles.includes(relativePath);
}

function generateDirectoryTree(dir, prefix = '', isLast = true) {
    let tree = '';
    const items = fs.readdirSync(dir, { withFileTypes: true });

    // Filtere nur Verzeichnisse und Dart-Dateien, die nicht ausgeschlossen sind
    const filteredItems = items.filter(item => {
        const fullPath = path.join(dir, item.name);
        if (item.isDirectory()) return true;
        return path.extname(fullPath) === '.dart' && !shouldExclude(fullPath);
    });

    // Sortiere: zuerst Verzeichnisse, dann Dateien
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

function addLineNumbers(content) {
    const lines = content.split('\n');
    const maxLineNumberLength = String(lines.length).length;

    return lines.map((line, index) => {
        const lineNumber = (index + 1).toString().padStart(maxLineNumberLength, ' ');
        return `${lineNumber}: ${line}`;
    }).join('\n');
}

function processDirectory(dir) {
    let content = '';
    const items = fs.readdirSync(dir, { withFileTypes: true });

    // Sortiere Elemente: zuerst Verzeichnisse, dann Dateien
    items.sort((a, b) => {
        if (a.isDirectory() && !b.isDirectory()) return -1;
        if (!a.isDirectory() && b.isDirectory()) return 1;
        return a.name.localeCompare(b.name);
    });

    for (const item of items) {
        const fullPath = path.join(dir, item.name);

        if (item.isDirectory()) {
            content += processDirectory(fullPath);
        } else if (path.extname(fullPath) === '.dart' && !shouldExclude(fullPath)) {
            const relativePath = path.relative(projectRoot, fullPath);
            const fileContent = fs.readFileSync(fullPath, 'utf8');
            const numberedContent = addLineNumbers(fileContent);

            // Füge eine Leerzeile nach der Dateiüberschrift hinzu
            content += `\n// ==== ${relativePath} ====\n\n`;
            content += numberedContent;
            content += '\n'; // Füge eine Leerzeile am Ende der Datei hinzu
        }
    }

    return content;
}

if (fs.existsSync(libDir)) {
    // Generiere die Verzeichnisstruktur
    const directoryTree = generateDirectoryTree(libDir);

    // Generiere die Dateiinhalte mit Zeilennummern
    const exportContent = processDirectory(libDir);

    // Kombiniere beides in der Ausgabedatei
    const combinedContent = `Verzeichnisstruktur des lib-Ordners:\n\n${directoryTree}\n\n${'='.repeat(80)}\n\nDateiinhalte:\n${exportContent}`;

    fs.writeFileSync(outputFile, combinedContent, 'utf8');
    console.log(`Verzeichnisstruktur und Dateiinhalte wurden in ${outputFile} exportiert.`);
} else {
    console.error('Das lib-Verzeichnis wurde nicht gefunden!');
}
