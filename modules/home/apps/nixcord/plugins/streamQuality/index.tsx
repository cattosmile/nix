/*
 * Vencord, a Discord client mod
 * Copyright (c) 2026 Equicord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Equicord user plugin

import "./style.css";

import { definePluginSettings } from "@api/Settings";
import { Button } from "@components/Button";
import { classNameFactory } from "@utils/css";
import definePlugin, { OptionType } from "@utils/types";
import type { RenderModalProps } from "@vencord/discord-types";
import { findByPropsLazy } from "@webpack";
import { Menu, Modal, openModal, React, TabBar, TextInput, useState } from "@webpack/common";
import defaultPreviewBase64 from "file://default-preview.png?base64";

const MediaEngineStore = findByPropsLazy("getMediaEngine");
const cl = classNameFactory("vc-sq-");
const DEFAULT_PREVIEW = `data:image/png;base64,${defaultPreviewBase64}`;

const MAX_PREVIEW_KB = 200;
const MAX_PREVIEW_BYTES = MAX_PREVIEW_KB * 1024;
const PREVIEW_OUT_W = 1280;
const PREVIEW_OUT_H = 720;
const STREAM_BITRATE_MIN = 3_500_000;
const STREAM_BITRATE_TARGET = 8_000_000;
const STREAM_BITRATE_MAX = 8_000_000;
const CROP_STAGE_W = 392;
const CROP_STAGE_H = 216;
const CROP_FRAME_W = 336;
const CROP_FRAME_H = Math.round(CROP_FRAME_W * 9 / 16);
const CROP_FRAME_LEFT = (CROP_STAGE_W - CROP_FRAME_W) / 2;
const CROP_FRAME_TOP = (CROP_STAGE_H - CROP_FRAME_H) / 2;

let forceQualityMetadataUpdate = false;

function applyQualityNow(forceMetadata = false) {
    const engine = MediaEngineStore?.getMediaEngine?.();
    if (!engine?.eachConnection) return;

    forceQualityMetadataUpdate = forceMetadata;
    try {
        engine.eachConnection((conn: any) => {
            if (conn.context === "stream" && conn.hasDesktopSource?.() && conn.setDesktopEncodingOptions) {
                const w = parse(settings.store.resolution) ?? 1080;
                const h = Math.round(w * 16 / 9);
                const f = parse(settings.store.fps) ?? 30;
                conn.setDesktopEncodingOptions(h, w, f);
            }
        });
    } finally {
        forceQualityMetadataUpdate = false;
    }
}

const settings = definePluginSettings({
    resolution: {
        description: "Stream resolution height.",
        type: OptionType.STRING,
        default: "1080",
    },
    fps: {
        description: "Stream FPS.",
        type: OptionType.STRING,
        default: "30",
    },
    spoofResolution: {
        description: "Spoof stream resolution badge (0 to disable).",
        type: OptionType.STRING,
        default: "0",
    },
    spoofFps: {
        description: "Spoof stream FPS badge (0 to disable).",
        type: OptionType.STRING,
        default: "0",
    },
    fakePreview: {
        description: "Custom preview image (base64 data URL).",
        type: OptionType.STRING,
        default: "",
    },
});

type QualityDraft = {
    resolution: string;
    fps: string;
    spoofResolution: string;
    spoofFps: string;
};

function getDefaultQualityDraft(): QualityDraft {
    return {
        resolution: "1080",
        fps: "30",
        spoofResolution: "0",
        spoofFps: "0",
    };
}

function readQualityDraft(): QualityDraft {
    return {
        resolution: settings.store.resolution,
        fps: settings.store.fps,
        spoofResolution: settings.store.spoofResolution,
        spoofFps: settings.store.spoofFps,
    };
}

function commitQualityDraft(draft: QualityDraft) {
    settings.store.resolution = draft.resolution;
    settings.store.fps = draft.fps;
    settings.store.spoofResolution = draft.spoofResolution;
    settings.store.spoofFps = draft.spoofFps;
}

function readFileAsDataURL(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result as string);
        reader.onerror = () => reject(new Error("Failed to read file"));
        reader.readAsDataURL(file);
    });
}

function CropPanel({ srcDataUrl, onSave, onCancel }: { srcDataUrl: string; onSave: (dataUrl: string) => void; onCancel: () => void; }) {
    const viewportRef = React.useRef<HTMLDivElement>(null);
    const [imgSize, setImgSize] = React.useState({ w: 0, h: 0 });
    const [scale, setScale] = React.useState(1);
    const [pos, setPos] = React.useState({ x: 0, y: 0 });
    const minScaleRef = React.useRef(1);
    const dragRef = React.useRef<{ startX: number; startY: number; origX: number; origY: number; } | null>(null);

    React.useEffect(() => {
        const img = new Image();
        img.onload = () => setImgSize({ w: img.naturalWidth, h: img.naturalHeight });
        img.src = srcDataUrl;
    }, [srcDataUrl]);

    React.useEffect(() => {
        if (imgSize.w === 0 || imgSize.h === 0) return;
        const cover = Math.max(CROP_FRAME_W / imgSize.w, CROP_FRAME_H / imgSize.h);
        minScaleRef.current = cover;
        setScale(cover);
        setPos({
            x: (CROP_STAGE_W - imgSize.w * cover) / 2,
            y: (CROP_STAGE_H - imgSize.h * cover) / 2,
        });
    }, [imgSize.w, imgSize.h]);

    const clampPos = (x: number, y: number, s: number) => {
        const iw = imgSize.w * s;
        const ih = imgSize.h * s;
        const maxX = CROP_FRAME_LEFT;
        const minX = CROP_FRAME_LEFT + CROP_FRAME_W - iw;
        const maxY = CROP_FRAME_TOP;
        const minY = CROP_FRAME_TOP + CROP_FRAME_H - ih;
        return {
            x: Math.max(minX, Math.min(maxX, x)),
            y: Math.max(minY, Math.min(maxY, y)),
        };
    };

    const onMouseDown = (e: React.MouseEvent) => {
        e.preventDefault();
        dragRef.current = { startX: e.clientX, startY: e.clientY, origX: pos.x, origY: pos.y };
    };
    const onMouseMove = (e: React.MouseEvent) => {
        if (!dragRef.current) return;
        const dx = e.clientX - dragRef.current.startX;
        const dy = e.clientY - dragRef.current.startY;
        setPos(clampPos(dragRef.current.origX + dx, dragRef.current.origY + dy, scale));
    };
    const endDrag = () => { dragRef.current = null; };

    const onWheel = (e: React.WheelEvent) => {
        e.preventDefault();
        const rect = viewportRef.current?.getBoundingClientRect();
        if (!rect) return;
        const cx = e.clientX - rect.left;
        const cy = e.clientY - rect.top;
        const factor = e.deltaY < 0 ? 1.1 : 1 / 1.1;
        const minS = minScaleRef.current;
        const newScale = Math.max(minS, Math.min(minS * 3, scale * factor));
        const dx = (cx - pos.x) / scale;
        const dy = (cy - pos.y) / scale;
        setScale(newScale);
        setPos(clampPos(cx - dx * newScale, cy - dy * newScale, newScale));
    };

    const handleSave = () => {
        if (imgSize.w === 0) return;
        const sx = (CROP_FRAME_LEFT - pos.x) / scale;
        const sy = (CROP_FRAME_TOP - pos.y) / scale;
        const sw = CROP_FRAME_W / scale;
        const sh = CROP_FRAME_H / scale;
        const canvas = document.createElement("canvas");
        canvas.width = PREVIEW_OUT_W;
        canvas.height = PREVIEW_OUT_H;
        const ctx = canvas.getContext("2d");
        if (!ctx) return;
        const img = new Image();
        img.onload = () => {
            ctx.drawImage(img, sx, sy, sw, sh, 0, 0, PREVIEW_OUT_W, PREVIEW_OUT_H);
            let quality = 0.85;
            let result = canvas.toDataURL("image/jpeg", quality);
            while (result.length > MAX_PREVIEW_BYTES * 1.36 && quality > 0.25) {
                quality -= 0.1;
                result = canvas.toDataURL("image/jpeg", quality);
            }
            onSave(result);
        };
        img.src = srcDataUrl;
    };

    const sliderValue = minScaleRef.current > 0 ? scale / minScaleRef.current : 1;

    return (
        <div className={cl("crop")}>
            <div className={cl("section-header")}>
                <span className={cl("section-title")}>Crop Preview</span>
                <div className={cl("section-line")} />
            </div>
            <div
                ref={viewportRef}
                className={cl("crop-viewport")}
                onMouseDown={onMouseDown}
                onMouseMove={onMouseMove}
                onMouseUp={endDrag}
                onMouseLeave={endDrag}
                onWheel={onWheel}
                style={{ width: CROP_STAGE_W, height: CROP_STAGE_H }}
            >
                <img
                    className={cl("crop-img")}
                    src={srcDataUrl}
                    draggable={false}
                    style={{
                        transform: `translate(${pos.x}px, ${pos.y}px) scale(${scale})`,
                        transformOrigin: "0 0",
                        width: imgSize.w || "auto",
                        height: imgSize.h || "auto",
                    }}
                />
                <div
                    className={cl("crop-frame")}
                    style={{
                        left: CROP_FRAME_LEFT,
                        top: CROP_FRAME_TOP,
                        width: CROP_FRAME_W,
                        height: CROP_FRAME_H,
                    }}
                />
            </div>
            <div className={cl("crop-controls")}>
                <span className={cl("crop-hint")}>Drag image to reposition</span>
                <input
                    type="range"
                    min={1}
                    max={3}
                    step={0.02}
                    value={sliderValue}
                    onChange={e => {
                        const t = parseFloat(e.target.value);
                        const newScale = minScaleRef.current * t;
                        setScale(newScale);
                        setPos(p => clampPos(p.x, p.y, newScale));
                    }}
                    className={cl("crop-zoom")}
                    style={{ "--vc-sq-zoom-pct": `${((sliderValue - 1) / 2) * 100}%` } as React.CSSProperties}
                />
            </div>
            <div className={cl("crop-actions")}>
                <Button variant="secondary" onClick={onCancel}>Cancel</Button>
                <Button onClick={handleSave}>Use this crop</Button>
            </div>
        </div>
    );
}

function QualityTab({ values, onChange }: {
    values: QualityDraft;
    onChange: (field: keyof QualityDraft, value: string) => void;
}) {
    return (
        <div className={cl("wrap")}>
            <div className={cl("section")}>
                <div className={cl("section-header")}>
                    <span className={cl("section-title")}>Stream Override</span>
                    <div className={cl("section-line")} />
                </div>
                <div className={cl("grid")}>
                    <div className={cl("field")}>
                        <span className={cl("field-label")}>Resolution</span>
                        <TextInput value={values.resolution} onChange={v => onChange("resolution", v)} placeholder="1080" />
                    </div>
                    <div className={cl("field")}>
                        <span className={cl("field-label")}>FPS</span>
                        <TextInput value={values.fps} onChange={v => onChange("fps", v)} placeholder="30" />
                    </div>
                </div>
                <span className={cl("info")}>Defaults to 1080p at 30 FPS. Changes are applied when you press Done.</span>
            </div>

            <div className={cl("section")}>
                <div className={cl("section-header")}>
                    <span className={cl("section-title")}>Badge Spoof</span>
                    <div className={cl("section-line")} />
                </div>
                <div className={cl("spoof-grid")}>
                    <div className={cl("field")}>
                        <span className={cl("field-label")}>Resolution</span>
                        <TextInput value={values.spoofResolution} onChange={v => onChange("spoofResolution", v)} placeholder="0 = off" />
                    </div>
                    <div className={cl("field")}>
                        <span className={cl("field-label")}>FPS</span>
                        <TextInput value={values.spoofFps} onChange={v => onChange("spoofFps", v)} placeholder="0 = off" />
                    </div>
                </div>
                <span className={cl("info")}>Spoofs the quality badge others see on your stream when you press Done. Separate from actual quality.</span>
            </div>
        </div>
    );
}

function PreviewTab({ onPickFile }: { onPickFile: () => void; }) {
    const preview = settings.store.fakePreview?.trim() || DEFAULT_PREVIEW;

    return (
        <div className={cl("wrap")}>
            <div className={cl("section")}>
                <div className={cl("section-header")}>
                    <span className={cl("section-title")}>Preview Image</span>
                    <div className={cl("section-line")} />
                </div>
                <button
                    type="button"
                    className={cl("preview-frame")}
                    aria-label="Change stream preview image"
                    onClick={onPickFile}
                >
                    <img className={cl("preview-img")} src={preview} alt="Stream preview" />
                    <span className={cl("preview-overlay")}>Change image</span>
                </button>
                <span className={cl("info")}>
                    Uses default-preview.png until you select a custom image. Crop to 16:9 for a perfect fit.
                </span>
            </div>
        </div>
    );
}

function StreamQualityModal({ modalProps }: { modalProps: RenderModalProps; }) {
    const [, forceUpdate] = useState(0);
    const refresh = () => forceUpdate(n => n + 1);
    const [qualityDraft, setQualityDraft] = useState<QualityDraft>(readQualityDraft());
    const [tab, setTab] = useState<"quality" | "preview">("quality");
    const [cropSrc, setCropSrc] = useState<string | null>(null);
    const fileInputRef = React.useRef<HTMLInputElement>(null);

    const startUpload = async (file: File) => {
        if (!file.type.startsWith("image/")) return;

        try {
            const dataUrl = await readFileAsDataURL(file);
            setCropSrc(dataUrl);
        } catch { }
    };

    return (
        <Modal
            {...modalProps}
            size="md"
            title="Stream Quality"
        >
            <div className={cl("tabs-row")}>
                <TabBar
                    type="top"
                    look="brand"
                    selectedItem={tab}
                    onItemSelect={(t: string) => setTab(t as typeof tab)}
                >
                    <TabBar.Item id="quality" className={cl("tab-item")}>Quality</TabBar.Item>
                    <TabBar.Item id="preview" className={cl("tab-item")}>Preview</TabBar.Item>
                </TabBar>
            </div>
            <div className={cl("modal-content")}>
                {tab === "quality" && (
                    <QualityTab
                        values={qualityDraft}
                        onChange={(field, value) => setQualityDraft(current => ({ ...current, [field]: value }))}
                    />
                )}
                {tab === "preview" && (
                    cropSrc ? (
                        <CropPanel
                            srcDataUrl={cropSrc}
                            onSave={dataUrl => {
                                settings.store.fakePreview = dataUrl;
                                setCropSrc(null);
                                refresh();
                            }}
                            onCancel={() => setCropSrc(null)}
                        />
                    ) : (
                        <PreviewTab onPickFile={() => fileInputRef.current?.click()} />
                    )
                )}
                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/png,image/jpeg,image/jpg,image/gif,image/webp"
                    style={{ display: "none" }}
                    onChange={e => {
                        const file = e.target.files?.[0];
                        if (file) startUpload(file);
                        e.target.value = "";
                    }}
                />
                {!(tab === "preview" && cropSrc) && (
                    <div className={cl("modal-actions")}>
                        <Button
                            variant="secondary"
                            onClick={() => {
                                setQualityDraft(getDefaultQualityDraft());
                                settings.store.fakePreview = "";
                                setCropSrc(null);
                                refresh();
                            }}
                        >
                            Reset
                        </Button>
                        <Button
                            onClick={() => {
                                commitQualityDraft(qualityDraft);
                                applyQualityNow(true);
                                modalProps.onClose();
                            }}
                        >
                            Done
                        </Button>
                    </div>
                )}
            </div>
        </Modal>
    );
}

function parse(val: string) {
    const v = parseInt(val);
    return isFinite(v) && v > 0 ? v : undefined;
}

export default definePlugin({
    name: "StreamQuality",
    description: "Override stream resolution and FPS. Spoof quality badges and screenshare thumbnail.",
    authors: [],
    settings,

    renderStreamQualityMenuItem(withSeparator = true) {
        return (
            <>
                {withSeparator && <Menu.MenuSeparator />}
                <Menu.MenuItem
                    id="stream-quality"
                    label="Stream Quality"
                    action={() => openModal(modalProps => <StreamQualityModal modalProps={modalProps} />)}
                />
            </>
        );
    },

    get spoofRes() { return parse(settings.store.spoofResolution); },
    get spoofFps() { return parse(settings.store.spoofFps); },

    getActualFps() { return parse(settings.store.fps); },
    getActualResolution() { return parse(settings.store.resolution); },
    getActualWidth() { const h = this.getActualResolution(); return h ? Math.round(h * 16 / 9) : undefined; },

    getStreamFps() { return this.getActualFps() ?? 30; },
    getStreamWidth() { return this.getActualWidth() ?? 1920; },
    getStreamHeight() { return this.getActualResolution() ?? 1080; },
    getStreamPixelCount() { return this.getStreamWidth() * this.getStreamHeight(); },
    getStreamBitrateMin() { return STREAM_BITRATE_MIN; },
    getStreamBitrateTarget() { return STREAM_BITRATE_TARGET; },
    getStreamBitrateMax() { return STREAM_BITRATE_MAX; },

    normalizeGoLiveQuality(quality: any) {
        const w = this.getStreamWidth(), h = this.getStreamHeight(), f = this.getStreamFps();
        return {
            ...quality,
            capture: { ...quality?.capture, width: w, height: h, framerate: f },
            encode: { ...quality?.encode, width: w, height: h, framerate: f, pixelCount: w * h },
            bitrateMin: this.getStreamBitrateMin(),
            bitrateTarget: this.getStreamBitrateTarget(),
            bitrateMax: this.getStreamBitrateMax(),
        };
    },

    coerceResolution(value: any) {
        if (!this.getActualResolution() || typeof value !== "object" || value == null) return value;
        const next = { ...value };
        if ((next.width ?? 0) <= 0) next.width = this.getStreamWidth();
        if ((next.height ?? 0) <= 0) next.height = this.getStreamHeight();
        return next;
    },

    coerceFrameRate(value: any) {
        if (!this.getActualFps()) return value;
        return (typeof value === "number" && value > 0) ? value : this.getStreamFps();
    },

    makeSelfResolution(settingValue: any) {
        if (!this.getActualResolution()) return { height: settingValue ?? 1080, width: 0, type: 0 };
        return { height: this.getStreamHeight(), width: this.getStreamWidth(), type: 0 };
    },

    getDisplayResolution(value: any) {
        if (typeof value !== "object" || value == null) return 0;
        const h = value.height ?? 0, w = value.width ?? 0;
        return h > 0 && w > 0 ? Math.max(h, Math.round(w * 9 / 16)) : h;
    },

    spoofQuality(real: any) {
        const v = this.spoofRes;
        if (!v) return real;
        return { type: 1, width: Math.round(v * 16 / 9), height: v };
    },

    spoofFpsVal(real: number) { return this.spoofFps ?? real; },

    patchStreamParams(params: any) {
        const res = this.spoofRes, fps = this.spoofFps;
        if (!res && !fps) return params;
        if (!Array.isArray(params)) return params;
        for (const p of params) {
            if (res && p.maxResolution) p.maxResolution = { ...p.maxResolution, width: Math.round(res * 16 / 9), height: res };
            if (fps) p.maxFrameRate = fps;
        }
        return params;
    },

    preview() {
        const custom = settings.store.fakePreview?.trim();
        return custom || DEFAULT_PREVIEW;
    },

    shouldForceQualityMetadataUpdate() {
        return forceQualityMetadataUpdate;
    },

    patches: [
        {
            find: '"stream-option-notify"',
            replacement: {
                match: /\i===\i\.\i\.PRESET_CUSTOM&&\(0,\i\.jsxs\)\(\i\.Fragment,\{children:\[\(0,\i\.jsx\)\(\i\.bX,\{\}\),\(0,\i\.jsx\)\(\i\.Dr,\{id:"resolution".{0,1800}?,\(0,\i\.jsx\)\(\i\.Dr,\{id:"frame-rate".{0,1400}?\}\)\]\}\)/,
                replace: "$self.renderStreamQualityMenuItem()",
            },
        },
        {
            find: '"stream-settings-audio-enable"',
            replacement: {
                match: /\(0,\i\.jsx\)\(\i\.Dr,\{id:"stream-settings",label:\i\.intl\.string\(\i\.t\.\i\),children:\i\}\)/,
                replace: "$self.renderStreamQualityMenuItem(false)",
            },
        },
        {
            find: "setDesktopEncodingOptions(",
            replacement: [
                {
                    match: /setDesktopEncodingOptions\((\i),(\i),(\i)\)\{/,
                    replace: "setDesktopEncodingOptions($1,$2,$3){if(this.destroyed)return;$1=$self.getStreamWidth();$2=$self.getStreamHeight();$3=$self.getStreamFps();",
                },
                {
                    match: /-1===(\i)&&\(\1=0\),(\i)&&\(this\.videoQualityManager\.setGoliveQuality/,
                    replace: "-1===$1&&($1=0),($self.shouldForceQualityMetadataUpdate()||$2)&&(this.videoQualityManager.setGoliveQuality",
                },
            ],
        },
        {
            find: "captureVideoFrameRate=n.capture.framerate",
            replacement: {
                match: /remoteSinkWantsMaxFramerate=\i\.encode\.framerate/,
                replace: "remoteSinkWantsMaxFramerate=$self.getStreamFps()",
            }
        },
        {
            find: "updateRemoteWantsFramerate(){",
            replacement: {
                match: /updateRemoteWantsFramerate\(\)\{/,
                replace: "$&this.connection.remoteSinkWantsMaxFramerate=$self.getStreamFps(),",
            }
        },
        {
            find: "setSDP(e){}setRemoteVideoSinkWants(",
            replacement: {
                match: /setRemoteVideoSinkWants\((\i)\)\{.{0,80}updateVideoQuality\((\i)\.(\i)\)\}/,
                replace: "setRemoteVideoSinkWants($1){this.remoteVideoSinkWants=$1,this.remoteSinkWantsMaxFramerate=$self.getStreamFps(),this.updateVideoQuality($2.$3)}",
            }
        },
        {
            find: "videoCapture.width",
            replacement: {
                match: /width:this\.options\.videoCapture\.width,height:this\.options\.videoCapture\.height,framerate:this\.options\.videoCapture\.framerate/,
                replace: "capture:{width:$self.getStreamWidth(),height:$self.getStreamHeight(),framerate:$self.getStreamFps()}",
            }
        },
        {
            find: "setGoliveQuality(",
            replacement: {
                match: /setGoliveQuality\((\i)\)\{/,
                replace: "setGoliveQuality($1){$1=$self.normalizeGoLiveQuality($1);",
            }
        },
        {
            find: "mediaEngineConnectionId=`WebRTC-",
            replacement: {
                match: /maxFrameRate:\i\.capture\?\.framerate,maxResolution:\{type:(\i)\.(\i)\.FIXED.{0,40}\}/,
                replace: "maxFrameRate:$self.getStreamFps(),maxResolution:{type:$1.$2.FIXED,width:$self.getStreamWidth(),height:$self.getStreamHeight()}",
            }
        },
        {
            find: "remoteSinkWantsPixelCount&&0!==",
            replacement: [
                {
                    match: /(\i)\.remoteSinkWantsPixelCount=\i\.encode\.pixelCount/,
                    replace: "$1.remoteSinkWantsPixelCount=$self.getStreamPixelCount()",
                },
                {
                    match: /null!=\i\.bitrateTarget\?(\i)\.encodingVideoBitRate=\i\.bitrateTarget:\1\.encodingVideoBitRate=\i\.bitrateMax/,
                    replace: "$1.encodingVideoBitRate=$self.getStreamBitrateTarget()",
                },
                {
                    match: /(\i)\.encodingVideoMinBitRate=\i\.bitrateMin/,
                    replace: "$1.encodingVideoMinBitRate=$self.getStreamBitrateMin()",
                },
                {
                    match: /(\i)\.encodingVideoMaxBitRate=\i\.bitrateMax/,
                    replace: "$1.encodingVideoMaxBitRate=$self.getStreamBitrateMax()",
                },
            ],
        },
        {
            find: "canUseQuestOrbMultiplier",
            replacement: {
                match: /function (\i)\((\i),(\i)\)\{return"high"===\2.{0,40}:"mid"===\2&&.{0,40}\}/,
                replace: "function $1($2,$3){return true}",
            }
        },
        {
            find: "\"canStreamWithSettings\"",
            replacement: {
                match: /\}\)\.allowAutoQuality;/,
                replace: "$&return!0;",
            }
        },
        {
            find: "#{intl::XjXqzh::raw}):h.intl.formatToPlainString(h.t#{intl::TEOC0I::raw}",
            replacement: {
                match: /\{maxFrameRate:(\i)\.fps,maxResolution:\{height:\1\.resolution,width:0,type:0===\1\.resolution\?\i\.\i\.SOURCE:\i\.\i\.FIXED\}\}/,
                replace: "{maxFrameRate:$self.getStreamFps(),maxResolution:$self.makeSelfResolution($1.resolution)}",
            }
        },
        {
            find: "intl.formatToPlainString(h.t#{intl::TEOC0I::raw},{resolution:",
            replacement: {
                match: /resolution:(\i)\.height/,
                replace: "resolution:$self.getDisplayResolution($1)",
            }
        },
        {
            find: "ChannelRTCStore\");",
            replacement: {
                match: /maxResolution:(\i),maxFrameRate:(\i),context:(\i)/,
                replace: "maxResolution:$self.coerceResolution($1),maxFrameRate:$self.coerceFrameRate($2),context:$3",
            }
        },
        {
            find: "ChannelRTCStore\");",
            replacement: {
                match: /updateParticipantQuality\((\i),(\i),(\i)\)/,
                replace: "updateParticipantQuality($1,$self.coerceResolution($2),$self.coerceFrameRate($3))",
            }
        },
        {
            find: "Attempting to downgrade to LQ simulcast stream",
            replacement: {
                match: /"LQ"===\i&&!\i&&\i&&\(/,
                replace: "false&&(",
            }
        },
        {
            find: "VideoSourceQualityChanged,this.guildId",
            replacement: [
                {
                    match: /this\.sendVideo\((\i)\?\?0,(\i)\?\?0,(\i)\?\?0,(\i)\)/,
                    replace: "this.sendVideo($1??0,$2??0,$3??0,$self.patchStreamParams($4))",
                },
                {
                    match: /(\i)\.maxResolution,(\i)\.maxFrameRate,this\.context\)/,
                    replace: "$self.spoofQuality($1.maxResolution),$self.spoofFpsVal($2.maxFrameRate),this.context)",
                },
            ],
        },
        {
            find: "case 1440:return 1440;case 0:return 0;default:",
            replacement: {
                match: /default:throw Error\(`Unknown resolution: \${(\i)}`\)/,
                replace: "return $1",
            }
        },
        {
            find: "\"ApplicationStreamPreviewUploadManager\"",
            replacement: {
                match: /thumbnail:([^,}]+)/,
                replace: "thumbnail:$self.preview($1)",
            },
        },
        {
            find: "\"ApplicationStreamPreviewUploadManager\"",
            replacement: [
                {
                    match: /(let \w+=)(\w+\.toDataURL\("image\/jpeg"\));/,
                    replace: "$1$self.preview($2);",
                },
                {
                    match: /(let \w+=)(\w+\.toDataURL\('image\/jpeg'\));/,
                    replace: "$1$self.preview($2);",
                },
            ],
        },
    ],
});
