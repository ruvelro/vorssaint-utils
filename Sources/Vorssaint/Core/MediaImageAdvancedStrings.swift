// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

struct MediaImageAdvancedStrings {
    let transform: String
    let rotation: String
    let noChange: String
    let flipHorizontal: String
    let flipVertical: String
    let crop: String

    static func localized(_ language: AppLanguage) -> MediaImageAdvancedStrings {
        switch language {
        case .enUS: return .init(transform: "Transform", rotation: "Rotation", noChange: "No change",
                                flipHorizontal: "Flip horizontally", flipVertical: "Flip vertically", crop: "Crop")
        case .ptBR: return .init(transform: "Transformar", rotation: "Rotação", noChange: "Sem alterar",
                                flipHorizontal: "Virar horizontalmente", flipVertical: "Virar verticalmente", crop: "Recortar")
        case .tr: return .init(transform: "Dönüştür", rotation: "Döndürme", noChange: "Değişiklik yok",
                              flipHorizontal: "Yatay çevir", flipVertical: "Dikey çevir", crop: "Kırp")
        case .ru: return .init(transform: "Преобразование", rotation: "Поворот", noChange: "Без изменений",
                              flipHorizontal: "Отразить по горизонтали", flipVertical: "Отразить по вертикали", crop: "Обрезка")
        case .es: return .init(transform: "Transformar", rotation: "Rotación", noChange: "Sin cambios",
                              flipHorizontal: "Voltear horizontalmente", flipVertical: "Voltear verticalmente", crop: "Recortar")
        case .de: return .init(transform: "Transformieren", rotation: "Drehung", noChange: "Keine Änderung",
                              flipHorizontal: "Horizontal spiegeln", flipVertical: "Vertikal spiegeln", crop: "Zuschneiden")
        case .fr: return .init(transform: "Transformer", rotation: "Rotation", noChange: "Aucun changement",
                              flipHorizontal: "Retourner horizontalement", flipVertical: "Retourner verticalement", crop: "Recadrer")
        case .it: return .init(transform: "Trasforma", rotation: "Rotazione", noChange: "Nessuna modifica",
                              flipHorizontal: "Rifletti orizzontalmente", flipVertical: "Rifletti verticalmente", crop: "Ritaglia")
        case .ja: return .init(transform: "変形", rotation: "回転", noChange: "変更なし",
                              flipHorizontal: "左右反転", flipVertical: "上下反転", crop: "切り抜き")
        case .ko: return .init(transform: "변형", rotation: "회전", noChange: "변경 없음",
                              flipHorizontal: "좌우 뒤집기", flipVertical: "상하 뒤집기", crop: "자르기")
        case .zhHans: return .init(transform: "变换", rotation: "旋转", noChange: "不更改",
                                  flipHorizontal: "水平翻转", flipVertical: "垂直翻转", crop: "裁剪")
        case .zhTW, .zhHK: return .init(transform: "變換", rotation: "旋轉", noChange: "不變更",
                                       flipHorizontal: "水平翻轉", flipVertical: "垂直翻轉", crop: "裁剪")
        }
    }
}
