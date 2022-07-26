// Constants
window.baseUrl = 'http://localhost:4040'

// Name prompt

function getNamePromptEl() {
    return document.getElementById("name-prompt");
}

function hideNamePrompt() {
    const el = getNamePromptEl();
    el.classList.add('hide');
}

// Board

function getBoardEl() {
    return document.getElementById("board");
}

function showBoard() {
    const board = getBoardEl();
    board.classList.remove('hide')
}

function setupBoard(state) {
    // This function is meant to execute only once
    const board = getBoardEl();
    board.style.gridTemplateColumns = `repeat(${state.size}, 200px)`
}

// Render

function getBoxForPos(x, y) {
    id = `${x},${y}`
    return document.getElementById(id);
}

function renderBoard(state) {
    clearBoard();
    renderBoxes(state.size);
    renderWalls(state.walls);
    renderPlayers(state.players);
}

function clearBoard() {
    const board = getBoardEl();
    board.innerHTML = "";
}

function renderBoxes(size) {
    const board = getBoardEl();

    const rows = [...Array(size).keys()]
    rows.forEach((row_i) => {
        // {0, 0} is at the bottom left
        const reversed_row_i = Math.abs(row_i - size + 1)

        columns = [...Array(size).keys()]
        columns.forEach((column_i) => {
            const pos = `${column_i},${reversed_row_i}`
            const box = document.createElement("div");
            box.id = pos;
            box.className = "box"
            //box.innerText = pos
            board.appendChild(box);
        })
    })
}

function renderWalls(walls) {
    const board = getBoardEl();

    walls.forEach((wall_pos) => {
        const [x, y] = wall_pos;
        box = getBoxForPos(x, y);
        box.className = "box wall"
    })
}

function renderPlayers(players) {
    players.forEach(([[x, y], name, is_alive]) => {
        box = getBoxForPos(x, y);

        player = document.createElement("div");
        player.innerText = name

        if (!is_alive) {
            player.className = "player player-dead"
        } else if (name == getPlayerName()) {
            player.className = "player player-self"
        } else {
            player.className = "player"
        }

        box.appendChild(player)
    })
}

// Controls

function getControlsEl() {
    return document.getElementById("controls");
}

function showControls() {
    controls = getControlsEl();
    controls.classList.remove('hide')
}

function walk(direction) {
    apiPostWalk(direction).then(([result, data]) => {
        if (result == "error") {
            alert(data)
        } else {
            gameLoop();
        }
    })
}

function attack() {
    apiPostAttack().then(([result, data]) => {
        if (result == "error") {
            alert(data);
        } else {
            alert(`${data} players killed!`);
            gameLoop();
        }
    })
}

// Utils

function getPlayerName() {
    return window.playerName;
}

function joinGame() {
    window.playerName = document.getElementById('player-name').value;
    hideNamePrompt();
    gameLoop();

    // Tick every 1s
    setInterval(gameLoop, 1000)
}

function gameLoop() {
    apiGetGameState().then((state) => {
        setupBoard(state);
        renderBoard(state);
        showControls();
        showBoard();
    });
}

// API

function apiGetGameState() {
    return _get(`/game?name=${getPlayerName()}`)
        .then((response) => response.json())
}

function apiPostWalk(direction) {
    return _post(`/game?name=${getPlayerName()}&action=walk&direction=${direction}`)
        .then((response) => response.json())
}

function apiPostAttack(direction) {
    return _post(`/game?name=${getPlayerName()}&action=attack`)
        .then((response) => response.json())
}

// HTTP

function _get(path) {
    return fetch(`${window.baseUrl}/${path}`);
}

function _post(path) {
    return fetch(`${window.baseUrl}/${path}`, {
        method: 'POST',
        body: {}
    });
}