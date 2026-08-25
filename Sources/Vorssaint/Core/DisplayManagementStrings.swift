// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct DisplayManagementStrings {
    let section: String
    let empty: String
    let presets: String
    let presetName: String
    let save: String
    let apply: String
    let deletePreset: String
    let emptyPresets: String
    let displayCountSingular: String
    let displayCountPlural: String
    let effects: String
    let effectsCaption: String
    let resolution: String
    let scale: String
    let native: String
    let makeMain: String
    let main: String
    let colorProfile: String
    let systemDefault: String
    let arrangement: String
    let imageAdjustments: String
    let contrast: String
    let gamma: String
    let gain: String
    let warmth: String
    let invertColors: String
    let pauseAdjustments: String
    let reset: String
    let updatePreset: String
}

extension FeatureStrings {
    static func displayManagement(_ language: AppLanguage) -> DisplayManagementStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension DisplayManagementStrings {
    static let enUS = DisplayManagementStrings(
        section: "Display management",
        empty: "No active displays found.",
        presets: "Display presets",
        presetName: "Preset name",
        save: "Save",
        apply: "Apply",
        deletePreset: "Delete preset",
        emptyPresets: "Save the current resolution, brightness, arrangement and color profile for all connected displays.",
        displayCountSingular: "1 display",
        displayCountPlural: "%d displays",
        effects: "Screen effects",
        effectsCaption: "These switches mirror the system display controls when the Mac exposes them.",
        resolution: "Resolution",
        scale: "Scale",
        native: "Native",
        makeMain: "Make main display",
        main: "Main",
        colorProfile: "Color profile",
        systemDefault: "System default",
        arrangement: "Arrangement",
        imageAdjustments: "Image adjustments",
        contrast: "Contrast",
        gamma: "Gamma",
        gain: "Gain",
        warmth: "Warmth",
        invertColors: "Invert colors",
        pauseAdjustments: "Pause adjustments",
        reset: "Reset",
        updatePreset: "Update from current displays"
    )

    static let ptBR = DisplayManagementStrings(
        section: "Gerenciamento de telas",
        empty: "Nenhuma tela ativa encontrada.",
        presets: "Predefinições de tela",
        presetName: "Nome da predefinição",
        save: "Salvar",
        apply: "Aplicar",
        deletePreset: "Apagar predefinição",
        emptyPresets: "Salve a resolução, brilho, organização e perfil de cor atuais de todas as telas conectadas.",
        displayCountSingular: "1 tela",
        displayCountPlural: "%d telas",
        effects: "Efeitos de tela",
        effectsCaption: "Estes controles acompanham os ajustes de tela do sistema quando o Mac os expõe.",
        resolution: "Resolução",
        scale: "Escala",
        native: "Nativa",
        makeMain: "Tornar tela principal",
        main: "Principal",
        colorProfile: "Perfil de cor",
        systemDefault: "Padrão do sistema",
        arrangement: "Organização",
        imageAdjustments: "Ajustes de imagem",
        contrast: "Contraste",
        gamma: "Gama",
        gain: "Ganho",
        warmth: "Calor",
        invertColors: "Inverter cores",
        pauseAdjustments: "Pausar ajustes",
        reset: "Redefinir",
        updatePreset: "Atualizar com as telas atuais"
    )

    static let tr = DisplayManagementStrings(
        section: "Ekran yönetimi",
        empty: "Etkin ekran bulunamadı.",
        presets: "Ekran ön ayarları",
        presetName: "Ön ayar adı",
        save: "Kaydet",
        apply: "Uygula",
        deletePreset: "Ön ayarı sil",
        emptyPresets: "Bağlı tüm ekranların mevcut çözünürlük, parlaklık, düzen ve renk profilini kaydedin.",
        displayCountSingular: "1 ekran",
        displayCountPlural: "%d ekran",
        effects: "Ekran efektleri",
        effectsCaption: "Mac bunları sunduğunda bu anahtarlar sistem ekran denetimlerini izler.",
        resolution: "Çözünürlük",
        scale: "Ölçek",
        native: "Yerel",
        makeMain: "Ana ekran yap",
        main: "Ana",
        colorProfile: "Renk profili",
        systemDefault: "Sistem varsayılanı",
        arrangement: "Düzen",
        imageAdjustments: "Görüntü ayarları",
        contrast: "Kontrast",
        gamma: "Gama",
        gain: "Kazanç",
        warmth: "Sıcaklık",
        invertColors: "Renkleri ters çevir",
        pauseAdjustments: "Ayarları duraklat",
        reset: "Sıfırla",
        updatePreset: "Geçerli ekranlardan güncelle"
    )

    static let ru = DisplayManagementStrings(
        section: "Управление экранами",
        empty: "Активные экраны не найдены.",
        presets: "Пресеты экранов",
        presetName: "Название пресета",
        save: "Сохранить",
        apply: "Применить",
        deletePreset: "Удалить пресет",
        emptyPresets: "Сохраните текущие разрешение, яркость, расположение и цветовой профиль для всех подключённых экранов.",
        displayCountSingular: "1 экран",
        displayCountPlural: "%d экранов",
        effects: "Эффекты экрана",
        effectsCaption: "Эти переключатели повторяют системные настройки экрана, когда Mac их предоставляет.",
        resolution: "Разрешение",
        scale: "Масштаб",
        native: "Родное",
        makeMain: "Сделать основным",
        main: "Основной",
        colorProfile: "Цветовой профиль",
        systemDefault: "Системный профиль",
        arrangement: "Расположение",
        imageAdjustments: "Настройки изображения",
        contrast: "Контраст",
        gamma: "Гамма",
        gain: "Усиление",
        warmth: "Теплота",
        invertColors: "Инвертировать цвета",
        pauseAdjustments: "Приостановить настройки",
        reset: "Сбросить",
        updatePreset: "Обновить текущими экранами"
    )

    static let es = DisplayManagementStrings(
        section: "Gestión de pantallas",
        empty: "No se encontró ninguna pantalla activa.",
        presets: "Presets de pantalla",
        presetName: "Nombre del preset",
        save: "Guardar",
        apply: "Aplicar",
        deletePreset: "Eliminar preset",
        emptyPresets: "Guarda la resolución, brillo, disposición y perfil de color actuales para todas las pantallas conectadas.",
        displayCountSingular: "1 pantalla",
        displayCountPlural: "%d pantallas",
        effects: "Efectos de pantalla",
        effectsCaption: "Estos interruptores reflejan los controles de pantalla del sistema cuando el Mac los expone.",
        resolution: "Resolución",
        scale: "Escala",
        native: "Nativa",
        makeMain: "Hacer principal",
        main: "Principal",
        colorProfile: "Perfil de color",
        systemDefault: "Predeterminado del sistema",
        arrangement: "Disposición",
        imageAdjustments: "Ajustes de imagen",
        contrast: "Contraste",
        gamma: "Gamma",
        gain: "Ganancia",
        warmth: "Calidez",
        invertColors: "Invertir colores",
        pauseAdjustments: "Pausar ajustes",
        reset: "Restablecer",
        updatePreset: "Actualizar desde pantallas actuales"
    )

    static let de = DisplayManagementStrings(
        section: "Displayverwaltung",
        empty: "Keine aktiven Displays gefunden.",
        presets: "Display-Presets",
        presetName: "Preset-Name",
        save: "Sichern",
        apply: "Anwenden",
        deletePreset: "Preset löschen",
        emptyPresets: "Speichere aktuelle Auflösung, Helligkeit, Anordnung und Farbprofil für alle verbundenen Displays.",
        displayCountSingular: "1 Display",
        displayCountPlural: "%d Displays",
        effects: "Bildschirmeffekte",
        effectsCaption: "Diese Schalter spiegeln die System-Displaysteuerung, wenn der Mac sie bereitstellt.",
        resolution: "Auflösung",
        scale: "Skalierung",
        native: "Nativ",
        makeMain: "Als Hauptdisplay",
        main: "Hauptdisplay",
        colorProfile: "Farbprofil",
        systemDefault: "Systemstandard",
        arrangement: "Anordnung",
        imageAdjustments: "Bildanpassungen",
        contrast: "Kontrast",
        gamma: "Gamma",
        gain: "Verstärkung",
        warmth: "Wärme",
        invertColors: "Farben umkehren",
        pauseAdjustments: "Anpassungen pausieren",
        reset: "Zurücksetzen",
        updatePreset: "Mit aktuellen Displays aktualisieren"
    )

    static let fr = DisplayManagementStrings(
        section: "Gestion des écrans",
        empty: "Aucun écran actif détecté.",
        presets: "Préréglages d'écran",
        presetName: "Nom du préréglage",
        save: "Enregistrer",
        apply: "Appliquer",
        deletePreset: "Supprimer le préréglage",
        emptyPresets: "Enregistrez la résolution, la luminosité, la disposition et le profil couleur actuels de tous les écrans connectés.",
        displayCountSingular: "1 écran",
        displayCountPlural: "%d écrans",
        effects: "Effets d'écran",
        effectsCaption: "Ces interrupteurs reflètent les contrôles d'écran du système lorsque le Mac les expose.",
        resolution: "Résolution",
        scale: "Échelle",
        native: "Native",
        makeMain: "Rendre principal",
        main: "Principal",
        colorProfile: "Profil couleur",
        systemDefault: "Par défaut système",
        arrangement: "Disposition",
        imageAdjustments: "Réglages d'image",
        contrast: "Contraste",
        gamma: "Gamma",
        gain: "Gain",
        warmth: "Chaleur",
        invertColors: "Inverser les couleurs",
        pauseAdjustments: "Suspendre les réglages",
        reset: "Réinitialiser",
        updatePreset: "Mettre à jour avec les écrans actuels"
    )

    static let it = DisplayManagementStrings(
        section: "Gestione schermi",
        empty: "Nessuno schermo attivo trovato.",
        presets: "Preset schermo",
        presetName: "Nome preset",
        save: "Salva",
        apply: "Applica",
        deletePreset: "Elimina preset",
        emptyPresets: "Salva risoluzione, luminosità, disposizione e profilo colore attuali per tutti gli schermi collegati.",
        displayCountSingular: "1 schermo",
        displayCountPlural: "%d schermi",
        effects: "Effetti schermo",
        effectsCaption: "Questi interruttori rispecchiano i controlli schermo di sistema quando il Mac li espone.",
        resolution: "Risoluzione",
        scale: "Scala",
        native: "Nativa",
        makeMain: "Rendi principale",
        main: "Principale",
        colorProfile: "Profilo colore",
        systemDefault: "Predefinito di sistema",
        arrangement: "Disposizione",
        imageAdjustments: "Regolazioni immagine",
        contrast: "Contrasto",
        gamma: "Gamma",
        gain: "Guadagno",
        warmth: "Calore",
        invertColors: "Inverti colori",
        pauseAdjustments: "Pausa regolazioni",
        reset: "Ripristina",
        updatePreset: "Aggiorna dagli schermi attuali"
    )

    static let ja = DisplayManagementStrings(
        section: "ディスプレイ管理",
        empty: "有効なディスプレイが見つかりません。",
        presets: "ディスプレイプリセット",
        presetName: "プリセット名",
        save: "保存",
        apply: "適用",
        deletePreset: "プリセットを削除",
        emptyPresets: "接続中のすべてのディスプレイの解像度、明るさ、配置、カラープロファイルを保存します。",
        displayCountSingular: "1台のディスプレイ",
        displayCountPlural: "%d台のディスプレイ",
        effects: "画面効果",
        effectsCaption: "Mac が提供している場合、システムのディスプレイ制御を反映します。",
        resolution: "解像度",
        scale: "スケール",
        native: "ネイティブ",
        makeMain: "メインにする",
        main: "メイン",
        colorProfile: "カラープロファイル",
        systemDefault: "システム標準",
        arrangement: "配置",
        imageAdjustments: "画像調整",
        contrast: "コントラスト",
        gamma: "ガンマ",
        gain: "ゲイン",
        warmth: "暖かさ",
        invertColors: "色を反転",
        pauseAdjustments: "調整を一時停止",
        reset: "リセット",
        updatePreset: "現在のディスプレイで更新"
    )

    static let ko = DisplayManagementStrings(
        section: "디스플레이 관리",
        empty: "활성 디스플레이를 찾을 수 없습니다.",
        presets: "디스플레이 프리셋",
        presetName: "프리셋 이름",
        save: "저장",
        apply: "적용",
        deletePreset: "프리셋 삭제",
        emptyPresets: "연결된 모든 디스플레이의 현재 해상도, 밝기, 배치 및 색상 프로파일을 저장합니다.",
        displayCountSingular: "디스플레이 1대",
        displayCountPlural: "디스플레이 %d대",
        effects: "화면 효과",
        effectsCaption: "Mac에서 제공될 때 시스템 디스플레이 제어를 그대로 반영합니다.",
        resolution: "해상도",
        scale: "스케일",
        native: "기본",
        makeMain: "주 디스플레이로 설정",
        main: "주 디스플레이",
        colorProfile: "색상 프로파일",
        systemDefault: "시스템 기본값",
        arrangement: "배치",
        imageAdjustments: "이미지 조정",
        contrast: "대비",
        gamma: "감마",
        gain: "게인",
        warmth: "따뜻함",
        invertColors: "색상 반전",
        pauseAdjustments: "조정 일시 정지",
        reset: "재설정",
        updatePreset: "현재 디스플레이로 업데이트"
    )

    static let zhHans = DisplayManagementStrings(
        section: "显示器管理",
        empty: "未找到活动显示器。",
        presets: "显示器预设",
        presetName: "预设名称",
        save: "保存",
        apply: "应用",
        deletePreset: "删除预设",
        emptyPresets: "保存所有已连接显示器当前的分辨率、亮度、排列和颜色描述文件。",
        displayCountSingular: "1 台显示器",
        displayCountPlural: "%d 台显示器",
        effects: "屏幕效果",
        effectsCaption: "当 Mac 提供这些系统显示控制时，这些开关会与其同步。",
        resolution: "分辨率",
        scale: "缩放",
        native: "原生",
        makeMain: "设为主显示器",
        main: "主显示器",
        colorProfile: "颜色描述文件",
        systemDefault: "系统默认",
        arrangement: "排列",
        imageAdjustments: "图像调整",
        contrast: "对比度",
        gamma: "伽马",
        gain: "增益",
        warmth: "暖度",
        invertColors: "反转颜色",
        pauseAdjustments: "暂停调整",
        reset: "重置",
        updatePreset: "用当前显示器更新"
    )

    static let zhTW = DisplayManagementStrings(
        section: "顯示器管理",
        empty: "找不到作用中的顯示器。",
        presets: "顯示器預設",
        presetName: "預設名稱",
        save: "儲存",
        apply: "套用",
        deletePreset: "刪除預設",
        emptyPresets: "儲存所有已連接顯示器目前的解析度、亮度、排列和色彩描述檔。",
        displayCountSingular: "1 台顯示器",
        displayCountPlural: "%d 台顯示器",
        effects: "螢幕效果",
        effectsCaption: "當 Mac 提供這些系統顯示控制時，這些開關會與其同步。",
        resolution: "解析度",
        scale: "縮放",
        native: "原生",
        makeMain: "設為主顯示器",
        main: "主顯示器",
        colorProfile: "色彩描述檔",
        systemDefault: "系統預設",
        arrangement: "排列",
        imageAdjustments: "影像調整",
        contrast: "對比",
        gamma: "Gamma",
        gain: "增益",
        warmth: "暖度",
        invertColors: "反轉色彩",
        pauseAdjustments: "暫停調整",
        reset: "重置",
        updatePreset: "用目前顯示器更新"
    )

    static let zhHK = DisplayManagementStrings(
        section: "顯示器管理",
        empty: "找不到使用中的顯示器。",
        presets: "顯示器預設",
        presetName: "預設名稱",
        save: "儲存",
        apply: "套用",
        deletePreset: "刪除預設",
        emptyPresets: "儲存所有已連接顯示器目前的解像度、亮度、排列和色彩描述檔。",
        displayCountSingular: "1 部顯示器",
        displayCountPlural: "%d 部顯示器",
        effects: "螢幕效果",
        effectsCaption: "當 Mac 提供這些系統顯示控制時，這些開關會與其同步。",
        resolution: "解像度",
        scale: "縮放",
        native: "原生",
        makeMain: "設為主顯示器",
        main: "主顯示器",
        colorProfile: "色彩描述檔",
        systemDefault: "系統預設",
        arrangement: "排列",
        imageAdjustments: "影像調整",
        contrast: "對比",
        gamma: "Gamma",
        gain: "增益",
        warmth: "暖度",
        invertColors: "反轉色彩",
        pauseAdjustments: "暫停調整",
        reset: "重設",
        updatePreset: "用目前顯示器更新"
    )
}
