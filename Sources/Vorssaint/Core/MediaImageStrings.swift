// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct MediaImageConverterStrings {
    let filesSelectedFormat: String
    let profile: String
    let noProfile: String
    let profileName: String
    let saveProfile: String
    let saveAsNew: String
    let updateProfile: String
    let deleteProfile: String
    let profileModified: String
    let profileDefaultNameFormat: String
    let presetWeb: String
    let presetSocial: String
    let presetDocs: String
    let resize: String
    let resizeNone: String
    let resizeMax: String
    let resizeWidth: String
    let resizeHeight: String
    let resizeExact: String
    let exactStretch: String
    let exactFit: String
    let exactFill: String
    let height: String
    let watermark: String
    let watermarkOff: String
    let watermarkText: String
    let watermarkLogo: String
    let watermarkBoth: String
    let watermarkTextPlaceholder: String
    let noLogo: String
    let chooseLogo: String
    let position: String
    let topLeft: String
    let topRight: String
    let center: String
    let bottomLeft: String
    let bottomRight: String
    let opacity: String
    let margin: String
    let scale: String
    let rename: String
    let preview: String
    let outputName: String
    let background: String
    let backgroundTransparent: String
    let backgroundWhite: String
    let backgroundBlack: String
    let preserveDate: String
    let copySummary: String
    let savedBytesFormat: String
    let grewBytesFormat: String
    let batchSavedFormat: String
    let batchPartialFormat: String
    let batchSummaryHeaderFormat: String
    let batchSummaryItemFormat: String

    static func localized(_ language: AppLanguage) -> MediaImageConverterStrings {
        language == .es ? .es : .enUS
    }

    static let enUS = MediaImageConverterStrings(
        filesSelectedFormat: "%d files selected",
        profile: "Profile",
        noProfile: "No profile",
        profileName: "Profile name",
        saveProfile: "Save",
        saveAsNew: "Save new",
        updateProfile: "Update",
        deleteProfile: "Delete profile",
        profileModified: "Modified",
        profileDefaultNameFormat: "Profile %d",
        presetWeb: "Web",
        presetSocial: "Social",
        presetDocs: "Docs",
        resize: "Resize",
        resizeNone: "No change",
        resizeMax: "Max side",
        resizeWidth: "Width",
        resizeHeight: "Height",
        resizeExact: "Custom",
        exactStretch: "Stretch",
        exactFit: "Fit",
        exactFill: "Fill",
        height: "Height",
        watermark: "Watermark",
        watermarkOff: "Off",
        watermarkText: "Text",
        watermarkLogo: "Logo",
        watermarkBoth: "Text + logo",
        watermarkTextPlaceholder: "Watermark text",
        noLogo: "No logo",
        chooseLogo: "Logo",
        position: "Position",
        topLeft: "Top left",
        topRight: "Top right",
        center: "Center",
        bottomLeft: "Bottom left",
        bottomRight: "Bottom right",
        opacity: "Opacity",
        margin: "Margin",
        scale: "Scale",
        rename: "Rename",
        preview: "Preview",
        outputName: "Output",
        background: "Background",
        backgroundTransparent: "Transparent",
        backgroundWhite: "White",
        backgroundBlack: "Black",
        preserveDate: "Keep original modified date",
        copySummary: "Copy summary",
        savedBytesFormat: "%@ saved",
        grewBytesFormat: "%@ larger",
        batchSavedFormat: "%d images saved",
        batchPartialFormat: "%d saved, %d failed",
        batchSummaryHeaderFormat: "%d saved, %d failed",
        batchSummaryItemFormat: "%@ -> %@"
    )

    static let es = MediaImageConverterStrings(
        filesSelectedFormat: "%d archivos seleccionados",
        profile: "Perfil",
        noProfile: "Sin perfil",
        profileName: "Nombre del perfil",
        saveProfile: "Guardar",
        saveAsNew: "Guardar nuevo",
        updateProfile: "Actualizar",
        deleteProfile: "Eliminar perfil",
        profileModified: "Modificado",
        profileDefaultNameFormat: "Perfil %d",
        presetWeb: "Web",
        presetSocial: "Social",
        presetDocs: "Docs",
        resize: "Redimensionar",
        resizeNone: "Sin cambios",
        resizeMax: "Lado máximo",
        resizeWidth: "Ancho proporcional",
        resizeHeight: "Alto proporcional",
        resizeExact: "Personalizado",
        exactStretch: "Estirar",
        exactFit: "Encajar",
        exactFill: "Rellenar",
        height: "Alto",
        watermark: "Marca de agua",
        watermarkOff: "Desactivada",
        watermarkText: "Texto",
        watermarkLogo: "Logo",
        watermarkBoth: "Texto + logo",
        watermarkTextPlaceholder: "Texto de marca de agua",
        noLogo: "Sin logo",
        chooseLogo: "Logo",
        position: "Posicion",
        topLeft: "Arriba izquierda",
        topRight: "Arriba derecha",
        center: "Centro",
        bottomLeft: "Abajo izquierda",
        bottomRight: "Abajo derecha",
        opacity: "Opacidad",
        margin: "Margen",
        scale: "Escala",
        rename: "Renombrar",
        preview: "Previsualizacion",
        outputName: "Salida",
        background: "Fondo",
        backgroundTransparent: "Transparente",
        backgroundWhite: "Blanco",
        backgroundBlack: "Negro",
        preserveDate: "Conservar fecha de modificacion",
        copySummary: "Copiar resumen",
        savedBytesFormat: "%@ ahorrados",
        grewBytesFormat: "%@ mas grande",
        batchSavedFormat: "%d imagenes guardadas",
        batchPartialFormat: "%d guardadas, %d fallidas",
        batchSummaryHeaderFormat: "%d guardadas, %d fallidas",
        batchSummaryItemFormat: "%@ -> %@"
    )
}
