let args = {
    "mainBackground": "#F9F9F9",
    "alertBackground": "#E8F6EF",
    "font": "Verdana, Geneva, Tahoma, sans-serif",
    "btnColOverPositive": "#185ADB",
    "btnColLeavePositive": "#029CE0",
    "btnColOverNegative": "#FF5D5D",
    "btnColLeaveNegative": "#FF8C8C",
    "title": "Alert !",
    "msg": "Replace this with your message",
    "btnName": "OK",
    "alertWidth": "400px",
    "paraCol": "#444444",
    "paraSize": "1.4rem",
    "titleBold": "800",
    "btnBold": "600",
    "paraBold": "400",
    "opacity": "1",
    "displayTitle": "block",
    "titleCol": "#444444",
    "disableBackground":"0",
    "reload": false,
    "reloadUrl":"this",
    "type":"positive"
}

const createAlert = (custom) => {
    let obj = args
    for (var c in custom) {
        obj[c] = custom[c]
    }
    const div = document.createElement("div")
    div.style.width = "100%"
    div.style.height = "100vh"
    div.style.position = "fixed"
    div.style.display = "flex"
    div.style.alignItems = "center"
    div.style.justifyContent = "center"
    div.style.top = "0"
    div.style.left = "0"
    div.style.right = "0"
    div.style.bottom = "0"
    div.style.zIndex="20000"
    div.style.backgroundColor = obj.mainBackground
    div.style.opacity = obj.opacity
    if(obj.disableBackground == "0"){
        div.style.background="#00000085"
    }
    const whiteDiv = document.createElement("div")
    whiteDiv.style.width = obj.alertWidth
    whiteDiv.style.height = "fit-content"
    whiteDiv.style.minHeight = "200px"
    whiteDiv.style.backgroundColor = obj.alertBackground
    whiteDiv.style.display = "flex"
    whiteDiv.style.flexDirection = "column"
    whiteDiv.style.justifyContent = "center"
    whiteDiv.style.alignItems = "center"
    whiteDiv.style.borderRadius = "0px"
    whiteDiv.style.padding = "16px"
    whiteDiv.style.fontFamily = obj.font

    const title = document.createElement("h2")
    title.style.fontFamily = obj.font
    title.style.width = "90%"
    title.style.textAlign = "center"
    title.style.userSelect = "none"
    title.innerHTML = obj.title
    title.style.marginBottom = "10px"
    title.style.display = obj.displayTitle
    title.style.color = obj.titleCol

    whiteDiv.appendChild(title)

    const para = document.createElement("p")
    para.style.color = obj.paraCol
    para.style.fontSize = obj.paraSize
    para.style.width = "90%"
    para.style.textAlign = "center"
    para.style.userSelect = "none"
    para.style.paddingBottom = "15px"
    para.style.overflowY = "auto"
    para.style.fontWeight = obj.paraBold
    const node = document.createTextNode(obj.msg)
    para.appendChild(node)
    whiteDiv.appendChild(para)

    const btn = document.createElement("button")
    btn.innerHTML = obj.btnName
    btn.width = "fit-content"
    btn.height = "50px"
    btn.style.padding = "15px"
    btn.style.boxShadow = "0 0 0 3px transparent"
    btn.style.fontFamily = obj.font
    btn.style.fontWeight = obj.btnBold
    btn.style.borderRadius = "0px"
    btn.style.border = "none"
    if(obj.type == "positive"){
        btn.style.backgroundColor = obj.btnColOverPositive
    }else{
        btn.style.backgroundColor = obj.btnColOverNegative
    }
    btn.style.color = "#E8F6FF"
    btn.style.cursor = "pointer"
    btn.style.marginBottom = "10px"
    btn.style.userSelect = "none"
    btn.addEventListener("mouseover", () => {
        if(obj.type == "positive"){
            btn.style.backgroundColor = obj.btnColLeavePositive
        }else{
            btn.style.backgroundColor = obj.btnColLeaveNegative
        }
    })
    btn.addEventListener("mouseleave", () => {
        if(obj.type == "positive"){
            btn.style.backgroundColor = obj.btnColOverPositive 
        }else{
            btn.style.backgroundColor = obj.btnColOverNegative
        }
    })
    btn.addEventListener("click", () => {
        div.style.display = 'none'
        document.body.removeChild(div)
        if(obj.reload){
            if(obj.reloadUrl != "this"){
               window.location.href=obj.reloadUrl
            }else{
                window.location.reload()
            }
        }
    })

    window.addEventListener("resize", () => {
        width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
        if (width < 768) {
            whiteDiv.style.width = "90%"
            para.style.fontSize = "15px"
            para.style.maxHeight = "350px"
        } else {
            whiteDiv.style.width = obj.alertWidth
            para.style.fontSize = "1.4rem"
            para.style.maxHeight = "100%"
        }
    })
    
    whiteDiv.appendChild(btn)
    div.appendChild(whiteDiv);
    document.body.appendChild(div)
    document.body.style.padding = "0px";
    document.body.style.margin = "0px";
}