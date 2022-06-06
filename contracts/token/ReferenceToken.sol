/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

/*

THE SYNDICATE | A BLACK MARKET PROJECT

Token Name: THE SYNDICATE    ($NWO)
Chain: Ethereum

Buy Tax: 6.0%
Sell Tax: 6.0%

Website: https://thesyndicate.info/
Telegram: https://t.me/SYNDICATE_NWO
Twitter: https://twitter.com/SYNDICATE_NWO
Facebook: https://www.facebook.com/The-Syndicate-106869828700402
Discord: https://discord.gg/z4Us9jyxn9
Medium: https://medium.com/@SYNDICATE_NWO
Reddit: https://www.reddit.com/r/SYNDICATE_NWO/

*/
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract THESYNDICATE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint) private cooldown;
    uint256 private constant _tTotal = 6666666666 * 10**_decimals;
    
    uint256 private _buyFee = 8;
    uint256 private _previousBuyFee = _buyFee;
    uint256 private _buyLiquidityFee = 2;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    
    uint256 private _sellFee = 8;
    uint256 private _previousSellFee = _sellFee;
    uint256 private _sellLiquidityFee = 2;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;

    uint256 private tokensForFee;
    uint256 private tokensForLiquidity;

    address payable private _feeWallet;
    address payable private _liquidityWallet;
    
    string private constant _name = "ELONminati";
    string private constant _symbol = "ELONminati";
    uint8 private constant _decimals = 18;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private swapping;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;

    uint256 private _maxBuyAmount = _tTotal;
    uint256 private _maxSellAmount = _tTotal;
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private swapTokensAtAmount = 0;
    
    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event MaxSellAmountUpdated(uint _maxSellAmount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _feeWallet = payable(0x7A13A6E784b5a4219d3551D6cdE85b7b6a1D6143);
        _liquidityWallet = payable(0x4CE471ddf977c5b037099862fACd16d493DE7869);
        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeWallet] = true;
        _isExcludedFromFee[_liquidityWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function setSwapEnabled(bool onoff) external onlyOwner(){
        swapEnabled = onoff;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = false;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {

            takeFee = true;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(amount <= _maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }

            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromFee[from] && cooldownEnabled) {
                require(amount <= _maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from,to,amount,takeFee, shouldSwap);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForFee;
        bool success;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForFee = ethBalance.mul(tokensForFee).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForFee;

        tokensForLiquidity = 0;
        tokensForFee = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        
        (success,) = address(_feeWallet).call{value: address(this).balance}("");
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWallet,
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _feeWallet.transfer(amount);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        _maxBuyAmount = _tTotal * 2 / 100;
        _maxSellAmount = _tTotal * 2 / 100;
        _maxWalletAmount = _tTotal * 3 / 100;
        swapTokensAtAmount = _tTotal * 5 / 10000;    // 0.05% of total
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function setMaxBuyAmount(uint256 maxBuy) public onlyOwner {
        _maxBuyAmount = maxBuy;
    }

    function setMaxSellAmount(uint256 maxSell) public onlyOwner {
        _maxSellAmount = maxSell;
    }
    
    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        _maxWalletAmount = maxToken;
    }
    
    function setSwapTokensAtAmount(uint256 newAmount) public onlyOwner {
        require(newAmount >= 50000 * 10**_decimals, "Swap amount cannot be lower than 0.1% total supply.");
        require(newAmount <= 10000001 * 10**_decimals, "Swap amount cannot be higher than 1.0% total supply.");
        swapTokensAtAmount = newAmount;
    }

    function setFeeWallet(address feeWallet) public onlyOwner() {
        require(feeWallet != address(0), "feeWallet address cannot be 0");
        _isExcludedFromFee[_feeWallet] = false;
        _feeWallet = payable(feeWallet);
        _isExcludedFromFee[_feeWallet] = true;
    }

    function setLiquidityWallet(address liquidityWallet) public onlyOwner() {
        require(liquidityWallet != address(0), "liquidityWallet address cannot be 0");
        _isExcludedFromFee[_liquidityWallet] = false;
        _liquidityWallet = payable(liquidityWallet);
        _isExcludedFromFee[_liquidityWallet] = true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyFee(uint256 buyFee, uint256 buyLiquidityFee) external onlyOwner {
        require(buyFee + buyLiquidityFee <= 30, "Must keep buy taxes below 30%");
        _buyFee = buyFee;
        _buyLiquidityFee = buyLiquidityFee;
    }

    function setSellFee(uint256 sellFee, uint256 sellLiquidityFee) external onlyOwner {
        require(sellFee + sellLiquidityFee <= 30, "Must keep sell taxes below 60%");
        _sellFee = sellFee;
        _sellLiquidityFee = sellLiquidityFee;
    }

    function removeAllFee() private {
        if(_buyFee == 0 && _buyLiquidityFee == 0 && _sellFee == 0 && _sellLiquidityFee == 0) return;
        
        _previousBuyFee = _buyFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousSellFee = _sellFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        
        _buyFee = 0;
        _buyLiquidityFee = 0;
        _sellFee = 0;
        _sellLiquidityFee = 0;
    }

    function restoreAllFee() private {
        _buyFee = _previousBuyFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;
        _sellFee = _previousSellFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        uint256 fee;
        uint256 liqFee;
        _totalFees = _getTotalFees(isSell);
        if (isSell) {
            fee = _sellFee;
            liqFee = _sellLiquidityFee;
        } else {
            fee = _buyFee;
            liqFee = _buyLiquidityFee;
        }

        uint256 fees = amount.mul(_totalFees).div(100);
        tokensForFee += fees * fee / _totalFees;
        tokensForLiquidity += fees * liqFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    receive() external payable {}
    
    function manualswap() public onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() public onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        require(!tradingOpen, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellFee + _sellLiquidityFee;
        }
        return _buyFee + _buyLiquidityFee;
    }
}