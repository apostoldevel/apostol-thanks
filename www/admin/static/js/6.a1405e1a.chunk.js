(this["webpackJsonpwieldy-hook"]=this["webpackJsonpwieldy-hook"]||[]).push([[6],{780:function(e,t,n){"use strict";n.d(t,"a",(function(){return r}));var a=n(0);function r(){var e=a.useRef(!0);return a.useEffect((function(){return function(){e.current=!1}}),[]),function(){return!e.current}}},781:function(e,t,n){"use strict";var a=n(5),r=n(7),o=n(0),c=n(286),l=n(287),i=n(780);function u(e){return!(!e||!e.then)}t.a=function(e){var t=o.useRef(!1),n=o.useRef(),s=Object(i.a)(),f=o.useState(!1),p=Object(r.a)(f,2),d=p[0],b=p[1];o.useEffect((function(){var t;if(e.autoFocus){var a=n.current;t=setTimeout((function(){return a.focus()}))}return function(){t&&clearTimeout(t)}}),[]);var v=e.type,m=e.children,y=e.prefixCls,O=e.buttonProps;return o.createElement(c.a,Object(a.a)({},Object(l.a)(v),{onClick:function(n){var a=e.actionFn,r=e.close;if(!t.current)if(t.current=!0,a){var o;if(e.emitEvent){if(o=a(n),e.quitOnNullishReturnValue&&!u(o))return t.current=!1,void r(n)}else if(a.length)o=a(r),t.current=!1;else if(!(o=a()))return void r();!function(n){var a=e.close;u(n)&&(b(!0),n.then((function(){s()||b(!1),a.apply(void 0,arguments),t.current=!1}),(function(e){console.error(e),s()||b(!1),t.current=!1})))}(o)}else r()},loading:d,prefixCls:y},O,{ref:n}),m)}},808:function(e,t,n){"use strict";var a=n(809),r={"text/plain":"Text","text/html":"Url",default:"Text"};e.exports=function(e,t){var n,o,c,l,i,u,s=!1;t||(t={}),n=t.debug||!1;try{if(c=a(),l=document.createRange(),i=document.getSelection(),(u=document.createElement("span")).textContent=e,u.style.all="unset",u.style.position="fixed",u.style.top=0,u.style.clip="rect(0, 0, 0, 0)",u.style.whiteSpace="pre",u.style.webkitUserSelect="text",u.style.MozUserSelect="text",u.style.msUserSelect="text",u.style.userSelect="text",u.addEventListener("copy",(function(a){if(a.stopPropagation(),t.format)if(a.preventDefault(),"undefined"===typeof a.clipboardData){n&&console.warn("unable to use e.clipboardData"),n&&console.warn("trying IE specific stuff"),window.clipboardData.clearData();var o=r[t.format]||r.default;window.clipboardData.setData(o,e)}else a.clipboardData.clearData(),a.clipboardData.setData(t.format,e);t.onCopy&&(a.preventDefault(),t.onCopy(a.clipboardData))})),document.body.appendChild(u),l.selectNodeContents(u),i.addRange(l),!document.execCommand("copy"))throw new Error("copy command was unsuccessful");s=!0}catch(f){n&&console.error("unable to copy using execCommand: ",f),n&&console.warn("trying IE specific stuff");try{window.clipboardData.setData(t.format||"text",e),t.onCopy&&t.onCopy(window.clipboardData),s=!0}catch(f){n&&console.error("unable to copy using clipboardData: ",f),n&&console.error("falling back to prompt"),o=function(e){var t=(/mac os x/i.test(navigator.userAgent)?"\u2318":"Ctrl")+"+C";return e.replace(/#{\s*key\s*}/g,t)}("message"in t?t.message:"Copy to clipboard: #{key}, Enter"),window.prompt(o,e)}}finally{i&&("function"==typeof i.removeRange?i.removeRange(l):i.removeAllRanges()),u&&document.body.removeChild(u),c()}return s}},809:function(e,t){e.exports=function(){var e=document.getSelection();if(!e.rangeCount)return function(){};for(var t=document.activeElement,n=[],a=0;a<e.rangeCount;a++)n.push(e.getRangeAt(a));switch(t.tagName.toUpperCase()){case"INPUT":case"TEXTAREA":t.blur();break;default:t=null}return e.removeAllRanges(),function(){"Caret"===e.type&&e.removeAllRanges(),e.rangeCount||n.forEach((function(t){e.addRange(t)})),t&&t.focus()}}},812:function(e,t,n){"use strict";var a=n(4),r=n(0),o={icon:{tag:"svg",attrs:{viewBox:"64 64 896 896",focusable:"false"},children:[{tag:"path",attrs:{d:"M257.7 752c2 0 4-.2 6-.5L431.9 722c2-.4 3.9-1.3 5.3-2.8l423.9-423.9a9.96 9.96 0 000-14.1L694.9 114.9c-1.9-1.9-4.4-2.9-7.1-2.9s-5.2 1-7.1 2.9L256.8 538.8c-1.5 1.5-2.4 3.3-2.8 5.3l-29.5 168.2a33.5 33.5 0 009.4 29.8c6.6 6.4 14.9 9.9 23.8 9.9zm67.4-174.4L687.8 215l73.3 73.3-362.7 362.6-88.9 15.7 15.6-89zM880 836H144c-17.7 0-32 14.3-32 32v36c0 4.4 3.6 8 8 8h784c4.4 0 8-3.6 8-8v-36c0-17.7-14.3-32-32-32z"}}]},name:"edit",theme:"outlined"},c=n(18),l=function(e,t){return r.createElement(c.a,Object(a.a)(Object(a.a)({},e),{},{ref:t,icon:o}))};l.displayName="EditOutlined";t.a=r.forwardRef(l)},827:function(e,t,n){"use strict";var a=n(5),r=n(7),o=n(0),c=n(8),l=n.n(c),i=n(96),u=n(146),s=n(80),f=n(143),p=n(286),d=n(287),b=n(140),v=n(106),m=n(83),y=n(248),O=n(34),g=n(105),j=n(781),h=n(780),E=void 0,x=function(e,t){var n={};for(var a in e)Object.prototype.hasOwnProperty.call(e,a)&&t.indexOf(a)<0&&(n[a]=e[a]);if(null!=e&&"function"===typeof Object.getOwnPropertySymbols){var r=0;for(a=Object.getOwnPropertySymbols(e);r<a.length;r++)t.indexOf(a[r])<0&&Object.prototype.propertyIsEnumerable.call(e,a[r])&&(n[a[r]]=e[a[r]])}return n},w=o.forwardRef((function(e,t){var n=o.useContext(m.b).getPrefixCls,c=Object(i.a)(!1,{value:e.visible,defaultValue:e.defaultVisible}),u=Object(r.a)(c,2),w=u[0],C=u[1],S=Object(h.a)(),k=function(t,n){var a;S()||C(t),null===(a=e.onVisibleChange)||void 0===a||a.call(e,t,n)},R=function(e){k(!1,e)},N=function(t){var n;return null===(n=e.onConfirm)||void 0===n?void 0:n.call(E,t)},P=function(t){var n;k(!1,t),null===(n=e.onCancel)||void 0===n||n.call(E,t)},T=e.prefixCls,D=e.placement,z=e.children,M=e.overlayClassName,H=x(e,["prefixCls","placement","children","overlayClassName"]),I=n("popover",T),L=n("popconfirm",T),A=l()(L,M),V=o.createElement(b.a,{componentName:"Popconfirm",defaultLocale:v.a.Popconfirm},(function(t){return function(t,r){var c=e.okButtonProps,l=e.cancelButtonProps,i=e.title,u=e.cancelText,s=e.okText,f=e.okType,b=e.icon,v=e.showCancel,m=void 0===v||v;return o.createElement("div",{className:"".concat(t,"-inner-content")},o.createElement("div",{className:"".concat(t,"-message")},b,o.createElement("div",{className:"".concat(t,"-message-title")},Object(y.a)(i))),o.createElement("div",{className:"".concat(t,"-buttons")},m&&o.createElement(p.a,Object(a.a)({onClick:P,size:"small"},l),u||r.cancelText),o.createElement(j.a,{buttonProps:Object(a.a)(Object(a.a)({size:"small"},Object(d.a)(f)),c),actionFn:N,close:R,prefixCls:n("btn"),quitOnNullishReturnValue:!0,emitEvent:!0},s||r.okText)))}(I,t)})),K=n();return o.createElement(f.a,Object(a.a)({},H,{prefixCls:I,placement:D,onVisibleChange:function(t){e.disabled||k(t)},visible:w,overlay:V,overlayClassName:A,ref:t,transitionName:Object(g.b)(K,"zoom-big",e.transitionName)}),Object(O.a)(z,{onKeyDown:function(e){var t,n;o.isValidElement(z)&&(null===(n=null===z||void 0===z?void 0:(t=z.props).onKeyDown)||void 0===n||n.call(t,e)),function(e){e.keyCode===s.a.ESC&&w&&k(!1,e)}(e)}}))}));w.defaultProps={placement:"top",trigger:"click",okType:"primary",icon:o.createElement(u.a,null),disabled:!1},t.a=w},833:function(e,t,n){"use strict";var a=n(4),r=n(0),o={icon:{tag:"svg",attrs:{viewBox:"64 64 896 896",focusable:"false"},children:[{tag:"path",attrs:{d:"M360 184h-8c4.4 0 8-3.6 8-8v8h304v-8c0 4.4 3.6 8 8 8h-8v72h72v-80c0-35.3-28.7-64-64-64H352c-35.3 0-64 28.7-64 64v80h72v-72zm504 72H160c-17.7 0-32 14.3-32 32v32c0 4.4 3.6 8 8 8h60.4l24.7 523c1.6 34.1 29.8 61 63.9 61h454c34.2 0 62.3-26.8 63.9-61l24.7-523H888c4.4 0 8-3.6 8-8v-32c0-17.7-14.3-32-32-32zM731.3 840H292.7l-24.2-512h487l-24.2 512z"}}]},name:"delete",theme:"outlined"},c=n(18),l=function(e,t){return r.createElement(c.a,Object(a.a)(Object(a.a)({},e),{},{ref:t,icon:o}))};l.displayName="DeleteOutlined";t.a=r.forwardRef(l)},836:function(e,t,n){"use strict";var a=n(5),r=n(6),o=n(0),c=n(8),l=n.n(c),i=n(56),u=n(83),s=n(45),f=function(e,t){var n={};for(var a in e)Object.prototype.hasOwnProperty.call(e,a)&&t.indexOf(a)<0&&(n[a]=e[a]);if(null!=e&&"function"===typeof Object.getOwnPropertySymbols){var r=0;for(a=Object.getOwnPropertySymbols(e);r<a.length;r++)t.indexOf(a[r])<0&&Object.prototype.propertyIsEnumerable.call(e,a[r])&&(n[a[r]]=e[a[r]])}return n},p=function(e,t){var n=e.prefixCls,c=e.component,p=void 0===c?"article":c,d=e.className,b=e["aria-label"],v=e.setContentRef,m=e.children,y=f(e,["prefixCls","component","className","aria-label","setContentRef","children"]),O=t;return v&&(Object(s.a)(!1,"Typography","`setContentRef` is deprecated. Please use `ref` instead."),O=Object(i.a)(t,v)),o.createElement(u.a,null,(function(e){var t=e.getPrefixCls,c=e.direction,i=p,u=t("typography",n),s=l()(u,Object(r.a)({},"".concat(u,"-rtl"),"rtl"===c),d);return o.createElement(i,Object(a.a)({className:s,"aria-label":b,ref:O},y),m)}))},d=o.forwardRef(p);d.displayName="Typography";var b=d,v=n(26),m=n(43),y=n(7),O=n(96),g=n(98),j=n(808),h=n.n(j),E=n(812),x=n(755),w=n(4),C={icon:{tag:"svg",attrs:{viewBox:"64 64 896 896",focusable:"false"},children:[{tag:"path",attrs:{d:"M832 64H296c-4.4 0-8 3.6-8 8v56c0 4.4 3.6 8 8 8h496v688c0 4.4 3.6 8 8 8h56c4.4 0 8-3.6 8-8V96c0-17.7-14.3-32-32-32zM704 192H192c-17.7 0-32 14.3-32 32v530.7c0 8.5 3.4 16.6 9.4 22.6l173.3 173.3c2.2 2.2 4.7 4 7.4 5.5v1.9h4.2c3.5 1.3 7.2 2 11 2H704c17.7 0 32-14.3 32-32V224c0-17.7-14.3-32-32-32zM350 856.2L263.9 770H350v86.2zM664 888H414V746c0-22.1-17.9-40-40-40H232V264h432v624z"}}]},name:"copy",theme:"outlined"},S=n(18),k=function(e,t){return o.createElement(S.a,Object(w.a)(Object(w.a)({},e),{},{ref:t,icon:C}))};k.displayName="CopyOutlined";var R=o.forwardRef(k),N=n(113),P=n(290),T=n(140),D=n(80),z=function(e,t){var n={};for(var a in e)Object.prototype.hasOwnProperty.call(e,a)&&t.indexOf(a)<0&&(n[a]=e[a]);if(null!=e&&"function"===typeof Object.getOwnPropertySymbols){var r=0;for(a=Object.getOwnPropertySymbols(e);r<a.length;r++)t.indexOf(a[r])<0&&Object.prototype.propertyIsEnumerable.call(e,a[r])&&(n[a[r]]=e[a[r]])}return n},M={border:0,background:"transparent",padding:0,lineHeight:"inherit",display:"inline-block"},H=o.forwardRef((function(e,t){var n=e.style,r=e.noStyle,c=e.disabled,l=z(e,["style","noStyle","disabled"]),i={};return r||(i=Object(a.a)({},M)),c&&(i.pointerEvents="none"),i=Object(a.a)(Object(a.a)({},i),n),o.createElement("div",Object(a.a)({role:"button",tabIndex:0,ref:t},l,{onKeyDown:function(e){e.keyCode===D.a.ENTER&&e.preventDefault()},onKeyUp:function(t){var n=t.keyCode,a=e.onClick;n===D.a.ENTER&&a&&a()},style:i}))})),I=n(300),L=n(143),A={icon:{tag:"svg",attrs:{viewBox:"64 64 896 896",focusable:"false"},children:[{tag:"path",attrs:{d:"M864 170h-60c-4.4 0-8 3.6-8 8v518H310v-73c0-6.7-7.8-10.5-13-6.3l-141.9 112a8 8 0 000 12.6l141.9 112c5.3 4.2 13 .4 13-6.3v-75h498c35.3 0 64-28.7 64-64V178c0-4.4-3.6-8-8-8z"}}]},name:"enter",theme:"outlined"},V=function(e,t){return o.createElement(S.a,Object(w.a)(Object(w.a)({},e),{},{ref:t,icon:A}))};V.displayName="EnterOutlined";var K=o.forwardRef(V),B=n(296),U=n(34),F=function(e){var t=e.prefixCls,n=e["aria-label"],a=e.className,c=e.style,i=e.direction,u=e.maxLength,s=e.autoSize,f=void 0===s||s,p=e.value,d=e.onSave,b=e.onCancel,v=e.onEnd,m=e.enterIcon,O=void 0===m?o.createElement(K,null):m,g=o.useRef(),j=o.useRef(!1),h=o.useRef(),E=o.useState(p),x=Object(y.a)(E,2),w=x[0],C=x[1];o.useEffect((function(){C(p)}),[p]),o.useEffect((function(){if(g.current&&g.current.resizableTextArea){var e=g.current.resizableTextArea.textArea;e.focus();var t=e.value.length;e.setSelectionRange(t,t)}}),[]);var S=function(){d(w.trim())},k=l()(t,"".concat(t,"-edit-content"),Object(r.a)({},"".concat(t,"-rtl"),"rtl"===i),a);return o.createElement("div",{className:k,style:c},o.createElement(B.a,{ref:g,maxLength:u,value:w,onChange:function(e){var t=e.target;C(t.value.replace(/[\n\r]/g,""))},onKeyDown:function(e){var t=e.keyCode;j.current||(h.current=t)},onKeyUp:function(e){var t=e.keyCode,n=e.ctrlKey,a=e.altKey,r=e.metaKey,o=e.shiftKey;h.current!==t||j.current||n||a||r||o||(t===D.a.ENTER?(S(),null===v||void 0===v||v()):t===D.a.ESC&&b())},onCompositionStart:function(){j.current=!0},onCompositionEnd:function(){j.current=!1},onBlur:function(){S()},"aria-label":n,rows:1,autoSize:f}),null!==O?Object(U.a)(O,{className:"".concat(t,"-edit-content-confirm")}):null)};function W(e,t){return o.useMemo((function(){var n=!!e;return[n,Object(a.a)(Object(a.a)({},t),n&&"object"===Object(v.a)(e)?e:null)]}),[e])}function q(e){var t=Object(v.a)(e);return"string"===t||"number"===t}function J(e,t){for(var n=0,a=[],r=0;r<e.length;r+=1){if(n===t)return a;var o=e[r],c=n+(q(o)?String(o).length:1);if(c>t){var l=t-n;return a.push(String(o).slice(0,l)),a}a.push(o),n=c}return e}var X=function(e){var t=e.enabledMeasure,n=e.children,r=e.text,c=e.width,l=e.rows,i=e.onEllipsis,u=o.useState([0,0,0]),s=Object(y.a)(u,2),f=s[0],p=s[1],d=o.useState(0),b=Object(y.a)(d,2),v=b[0],m=b[1],O=Object(y.a)(f,3),j=O[0],h=O[1],E=O[2],x=o.useState(0),w=Object(y.a)(x,2),C=w[0],S=w[1],k=o.useRef(null),R=o.useRef(null),N=o.useMemo((function(){return Object(g.a)(r)}),[r]),T=o.useMemo((function(){return function(e){var t=0;return e.forEach((function(e){q(e)?t+=String(e).length:t+=1})),t}(N)}),[N]),D=o.useMemo((function(){return t&&3===v?n(J(N,h),h<T):n(N,!1)}),[t,v,n,N,h,T]);Object(P.a)((function(){t&&c&&T&&(m(1),p([0,Math.ceil(T/2),T]))}),[t,c,r,T,l]),Object(P.a)((function(){var e;1===v&&S((null===(e=k.current)||void 0===e?void 0:e.offsetHeight)||0)}),[v]),Object(P.a)((function(){var e,t;if(C)if(1===v)((null===(e=R.current)||void 0===e?void 0:e.offsetHeight)||0)<=l*C?(m(4),i(!1)):m(2);else if(2===v)if(j!==E){var n=(null===(t=R.current)||void 0===t?void 0:t.offsetHeight)||0,a=j,r=E;j===E-1?r=j:n<=l*C?a=h:r=h;var o=Math.ceil((a+r)/2);p([a,o,r])}else m(3),i(!0)}),[v,j,E,l,C]);var z={width:c,whiteSpace:"normal",margin:0,padding:0},M=function(e,t,n){return o.createElement("span",{"aria-hidden":!0,ref:t,style:Object(a.a)({position:"fixed",display:"block",left:0,top:0,zIndex:-9999,visibility:"hidden",pointerEvents:"none"},n)},e)};return o.createElement(o.Fragment,null,D,t&&3!==v&&4!==v&&o.createElement(o.Fragment,null,M("lg",k,{wordBreak:"keep-all",whiteSpace:"nowrap"}),1===v?M(n(N,!1),R,z):function(e,t){var a=J(N,e);return M(n(a,!0),t,z)}(h,R)))};var _=function(e){var t=e.title,n=e.enabledEllipsis,a=e.isEllipsis,r=e.children;return t&&n?o.createElement(L.a,{title:t,visible:!!a&&void 0},r):r},G=function(e,t){var n={};for(var a in e)Object.prototype.hasOwnProperty.call(e,a)&&t.indexOf(a)<0&&(n[a]=e[a]);if(null!=e&&"function"===typeof Object.getOwnPropertySymbols){var r=0;for(a=Object.getOwnPropertySymbols(e);r<a.length;r++)t.indexOf(a[r])<0&&Object.prototype.propertyIsEnumerable.call(e,a[r])&&(n[a[r]]=e[a[r]])}return n};function Q(e,t,n){return!0===e||void 0===e?t:e||n&&t}function Y(e){return Array.isArray(e)?e:[e]}var Z=o.forwardRef((function(e,t){var n=e.prefixCls,c=e.className,s=e.style,f=e.type,p=e.disabled,d=e.children,j=e.ellipsis,w=e.editable,C=e.copyable,S=e.component,k=e.title,D=G(e,["prefixCls","className","style","type","disabled","children","ellipsis","editable","copyable","component","title"]),z=o.useContext(u.b),M=z.getPrefixCls,A=z.direction,V=Object(T.b)("Text")[0],K=o.useRef(null),B=o.useRef(null),U=M("typography",n),q=Object(m.a)(D,["mark","code","delete","underline","strong","keyboard","italic"]),J=W(w),Z=Object(y.a)(J,2),$=Z[0],ee=Z[1],te=Object(O.a)(!1,{value:ee.editing}),ne=Object(y.a)(te,2),ae=ne[0],re=ne[1],oe=ee.triggerType,ce=void 0===oe?["icon"]:oe,le=function(e){var t;e&&(null===(t=ee.onStart)||void 0===t||t.call(ee)),re(e)};!function(e,t){var n=o.useRef(!1);o.useEffect((function(){n.current?e():n.current=!0}),t)}((function(){var e;ae||null===(e=B.current)||void 0===e||e.focus()}),[ae]);var ie=function(e){null===e||void 0===e||e.preventDefault(),le(!0)},ue=W(C),se=Object(y.a)(ue,2),fe=se[0],pe=se[1],de=o.useState(!1),be=Object(y.a)(de,2),ve=be[0],me=be[1],ye=o.useRef(),Oe=function(){clearTimeout(ye.current)},ge=function(e){var t;null===e||void 0===e||e.preventDefault(),null===e||void 0===e||e.stopPropagation(),void 0===pe.text&&(pe.text=String(d)),h()(pe.text||""),me(!0),Oe(),ye.current=setTimeout((function(){me(!1)}),3e3),null===(t=pe.onCopy)||void 0===t||t.call(pe)};o.useEffect((function(){return Oe}),[]);var je=o.useState(!1),he=Object(y.a)(je,2),Ee=he[0],xe=he[1],we=o.useState(!1),Ce=Object(y.a)(we,2),Se=Ce[0],ke=Ce[1],Re=o.useState(!1),Ne=Object(y.a)(Re,2),Pe=Ne[0],Te=Ne[1],De=o.useState(!1),ze=Object(y.a)(De,2),Me=ze[0],He=ze[1],Ie=o.useState(!1),Le=Object(y.a)(Ie,2),Ae=Le[0],Ve=Le[1],Ke=W(j,{expandable:!1}),Be=Object(y.a)(Ke,2),Ue=Be[0],Fe=Be[1],We=Ue&&!Pe,qe=Fe.rows,Je=void 0===qe?1:qe,Xe=o.useMemo((function(){return!We||void 0!==Fe.suffix||Fe.onEllipsis||Fe.expandable||$||fe}),[We,Fe,$,fe]);Object(P.a)((function(){Ue&&!Xe&&(xe(Object(I.a)("webkitLineClamp")),ke(Object(I.a)("textOverflow")))}),[Xe,Ue]);var _e=o.useMemo((function(){return!Xe&&(1===Je?Se:Ee)}),[Xe,Se,Ee]),Ge=We&&(_e?Ae:Me),Qe=We&&1===Je&&_e,Ye=We&&Je>1&&_e,Ze=function(e){var t;Te(!0),null===(t=Fe.onExpand)||void 0===t||t.call(Fe,e)},$e=o.useState(0),et=Object(y.a)($e,2),tt=et[0],nt=et[1],at=function(e){var t;He(e),Me!==e&&(null===(t=Fe.onEllipsis)||void 0===t||t.call(Fe,e))};o.useEffect((function(){var e=K.current;if(Ue&&_e&&e){var t=Ye?e.offsetHeight<e.scrollHeight:e.offsetWidth<e.scrollWidth;Ae!==t&&Ve(t)}}),[Ue,_e,d,Ye]);var rt=!0===Fe.tooltip?d:Fe.tooltip,ot=o.useMemo((function(){var e=function(e){return["string","number"].includes(Object(v.a)(e))};if(Ue&&!_e)return e(d)?d:e(k)?k:e(rt)?rt:void 0}),[Ue,_e,k,rt,Ge]);if(ae)return o.createElement(F,{value:"string"===typeof d?d:"",onSave:function(e){var t;null===(t=ee.onChange)||void 0===t||t.call(ee,e),le(!1)},onCancel:function(){var e;null===(e=ee.onCancel)||void 0===e||e.call(ee),le(!1)},onEnd:ee.onEnd,prefixCls:U,className:c,style:s,direction:A,maxLength:ee.maxLength,autoSize:ee.autoSize,enterIcon:ee.enterIcon});var ct=function(){var e,t=Fe.expandable,n=Fe.symbol;return t?(e=n||V.expand,o.createElement("a",{key:"expand",className:"".concat(U,"-expand"),onClick:Ze,"aria-label":V.expand},e)):null},lt=function(){if($){var e=ee.icon,t=ee.tooltip,n=Object(g.a)(t)[0]||V.edit,a="string"===typeof n?n:"";return ce.includes("icon")?o.createElement(L.a,{key:"edit",title:!1===t?"":n},o.createElement(H,{ref:B,className:"".concat(U,"-edit"),onClick:ie,"aria-label":a},e||o.createElement(E.a,{role:"button"}))):null}},it=function(){if(fe){var e=pe.tooltips,t=pe.icon,n=Y(e),a=Y(t),r=ve?Q(n[1],V.copied):Q(n[0],V.copy),c=ve?V.copied:V.copy,i="string"===typeof r?r:c;return o.createElement(L.a,{key:"copy",title:r},o.createElement(H,{className:l()("".concat(U,"-copy"),ve&&"".concat(U,"-copy-success")),onClick:ge,"aria-label":i},ve?Q(a[1],o.createElement(x.a,null),!0):Q(a[0],o.createElement(R,null),!0)))}};return o.createElement(N.a,{onResize:function(e){var t=e.offsetWidth;nt(t)},disabled:!We||_e},(function(n){var u;return o.createElement(_,{title:rt,enabledEllipsis:We,isEllipsis:Ge},o.createElement(b,Object(a.a)({className:l()((u={},Object(r.a)(u,"".concat(U,"-").concat(f),f),Object(r.a)(u,"".concat(U,"-disabled"),p),Object(r.a)(u,"".concat(U,"-ellipsis"),Ue),Object(r.a)(u,"".concat(U,"-single-line"),We&&1===Je),Object(r.a)(u,"".concat(U,"-ellipsis-single-line"),Qe),Object(r.a)(u,"".concat(U,"-ellipsis-multiple-line"),Ye),u),c),style:Object(a.a)(Object(a.a)({},s),{WebkitLineClamp:Ye?Je:void 0}),component:S,ref:Object(i.a)(n,K,t),direction:A,onClick:ce.includes("text")?ie:null,"aria-label":ot,title:k},q),o.createElement(X,{enabledMeasure:We&&!_e,text:d,rows:Je,width:tt,onEllipsis:at},(function(t,n){var a=t;t.length&&n&&ot&&(a=o.createElement("span",{key:"show-content","aria-hidden":!0},a));var r=function(e,t){var n=e.mark,a=e.code,r=e.underline,c=e.delete,l=e.strong,i=e.keyboard,u=e.italic,s=t;function f(e,t){e&&(s=o.createElement(t,{},s))}return f(l,"strong"),f(r,"u"),f(c,"del"),f(a,"code"),f(n,"mark"),f(i,"kbd"),f(u,"i"),s}(e,o.createElement(o.Fragment,null,a,function(e){return[e&&o.createElement("span",{"aria-hidden":!0,key:"ellipsis"},"..."),Fe.suffix,(t=e,[t&&ct(),lt(),it()])];var t}(n)));return r}))))}))})),$=function(e,t){var n={};for(var a in e)Object.prototype.hasOwnProperty.call(e,a)&&t.indexOf(a)<0&&(n[a]=e[a]);if(null!=e&&"function"===typeof Object.getOwnPropertySymbols){var r=0;for(a=Object.getOwnPropertySymbols(e);r<a.length;r++)t.indexOf(a[r])<0&&Object.prototype.propertyIsEnumerable.call(e,a[r])&&(n[a[r]]=e[a[r]])}return n},ee=function(e){var t=e.ellipsis,n=$(e,["ellipsis"]),r=o.useMemo((function(){return t&&"object"===Object(v.a)(t)?Object(m.a)(t,["expandable","rows"]):t}),[t]);return Object(s.a)("object"!==Object(v.a)(t)||!t||!("expandable"in t)&&!("rows"in t),"Typography.Text","`ellipsis` do not support `expandable` or `rows` props."),o.createElement(Z,Object(a.a)({},n,{ellipsis:r,component:"span"}))},te=function(e,t){var n={};for(var a in e)Object.prototype.hasOwnProperty.call(e,a)&&t.indexOf(a)<0&&(n[a]=e[a]);if(null!=e&&"function"===typeof Object.getOwnPropertySymbols){var r=0;for(a=Object.getOwnPropertySymbols(e);r<a.length;r++)t.indexOf(a[r])<0&&Object.prototype.propertyIsEnumerable.call(e,a[r])&&(n[a[r]]=e[a[r]])}return n},ne=function(e,t){var n=e.ellipsis,r=e.rel,c=te(e,["ellipsis","rel"]);Object(s.a)("object"!==Object(v.a)(n),"Typography.Link","`ellipsis` only supports boolean value.");var l=o.useRef(null);o.useImperativeHandle(t,(function(){return l.current}));var i=Object(a.a)(Object(a.a)({},c),{rel:void 0===r&&"_blank"===c.target?"noopener noreferrer":r});return delete i.navigate,o.createElement(Z,Object(a.a)({},i,{ref:l,ellipsis:!!n,component:"a"}))},ae=o.forwardRef(ne),re=n(65),oe=function(e,t){var n={};for(var a in e)Object.prototype.hasOwnProperty.call(e,a)&&t.indexOf(a)<0&&(n[a]=e[a]);if(null!=e&&"function"===typeof Object.getOwnPropertySymbols){var r=0;for(a=Object.getOwnPropertySymbols(e);r<a.length;r++)t.indexOf(a[r])<0&&Object.prototype.propertyIsEnumerable.call(e,a[r])&&(n[a[r]]=e[a[r]])}return n},ce=Object(re.b)(1,2,3,4,5),le=function(e){var t,n=e.level,r=void 0===n?1:n,c=oe(e,["level"]);return-1!==ce.indexOf(r)?t="h".concat(r):(Object(s.a)(!1,"Typography.Title","Title only accept `1 | 2 | 3 | 4 | 5` as `level` value. And `5` need 4.6.0+ version."),t="h1"),o.createElement(Z,Object(a.a)({},c,{component:t}))},ie=function(e){return o.createElement(Z,Object(a.a)({},e,{component:"div"}))},ue=b;ue.Text=ee,ue.Link=ae,ue.Title=le,ue.Paragraph=ie;t.a=ue}}]);