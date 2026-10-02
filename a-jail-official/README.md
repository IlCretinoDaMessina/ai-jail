<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="generator" content="docs.rs 0.0.0 (6b0955898af88db642c5ce7420d9dbef2c65d5d9 2026-09-30 )"><link rel="stylesheet" href="/-/static/vendored.css?0-0-0-6b0955898af88db642c5ce7420d9dbef2c65d5d9-2026-09-30" media="all" />
        <link rel="stylesheet" href="/-/static/style.css?0-0-0-6b0955898af88db642c5ce7420d9dbef2c65d5d9-2026-09-30" media="all" />
        <link rel="stylesheet" href="/-/static/font-awesome.css?0-0-0-6b0955898af88db642c5ce7420d9dbef2c65d5d9-2026-09-30" media="all" />

        <link rel="search" href="/-/static/opensearch.xml" type="application/opensearchdescription+xml" title="Docs.rs" />

        <title>ai-jail 2.2.0 - Docs.rs</title><script nonce="ShiN1iOHtQEcxQF1FVreBB+c6TAAOxSY9NDpSUWtolIqE0b2">(function() {
    function applyTheme(theme) {
        if (theme) {
            document.documentElement.dataset.docsRsTheme = theme;
        }
    }

    window.addEventListener("storage", ev => {
        if (ev.key === "rustdoc-theme") {
            applyTheme(ev.newValue);
        }
    });

    // see ./storage-change-detection.html for details
    window.addEventListener("message", ev => {
        if (ev.data && ev.data.storage && ev.data.storage.key === "rustdoc-theme") {
            applyTheme(ev.data.storage.value);
        }
    });

    applyTheme(window.localStorage.getItem("rustdoc-theme"));
})();</script><script defer type="text/javascript" nonce="ShiN1iOHtQEcxQF1FVreBB+c6TAAOxSY9NDpSUWtolIqE0b2" src="/-/static/menu.js?0-0-0-6b0955898af88db642c5ce7420d9dbef2c65d5d9-2026-09-30"></script>
        <script defer type="text/javascript" nonce="ShiN1iOHtQEcxQF1FVreBB+c6TAAOxSY9NDpSUWtolIqE0b2" src="/-/static/index.js?0-0-0-6b0955898af88db642c5ce7420d9dbef2c65d5d9-2026-09-30"></script>
    </head>

    <body class="flex">
<div class="nav-container">
    <div class="container">
        <div class="pure-menu pure-menu-horizontal" role="navigation" aria-label="Main navigation">
            <form action="/releases/search"
                  method="GET"
                  id="nav-search-form"
                  class="landing-search-form-nav  ">

                
                <a href="/" class="pure-menu-heading pure-menu-link docsrs-logo" aria-label="Docs.rs">
                    <span title="Docs.rs"><span class="fa fa-solid fa-cubes " aria-hidden="true"></span></span>
                    <span class="title">Docs.rs</span>
                </a><ul class="pure-menu-list">
    <script id="crate-metadata" type="application/json">
        
        {
            "name": "ai-jail",
            "version": "2.2.0"
        }
    </script><li class="pure-menu-item">
            <a href="/crate/ai-jail/2.2.0" class="pure-menu-link crate-name" title="Sandbox for AI coding agents (bubblewrap on Linux, sandbox-exec on macOS)">
                <span class="fa fa-solid fa-cube " aria-hidden="true"></span>
                <span class="title">ai-jail-2.2.0</span>
            </a>
        </li>
    
    <li id="crate-warnings" class="pure-menu-item hidden" data-url="/-/partial/crate-warnings/ai-jail/"></li>
</ul><div class="spacer"></div>
                
                <div id="abnormalities" class="hidden"></div>

                <ul class="pure-menu-list">
                    <li class="pure-menu-item pure-menu-has-children">
                        <a href="#" class="pure-menu-link" aria-label="docs.rs">docs.rs</a>
                        <ul class="pure-menu-children aligned-icons"><li class="pure-menu-item"><a class="pure-menu-link" href="/about"><span class="fa fa-solid fa-circle-info " aria-hidden="true"></span> About docs.rs</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="/about/badges"><span class="fa fa-brands fa-fonticons " aria-hidden="true"></span> Badges</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="/about/builds"><span class="fa fa-solid fa-gears " aria-hidden="true"></span> Builds</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="/about/metadata"><span class="fa fa-solid fa-table " aria-hidden="true"></span> Metadata</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="/about/redirections"><span class="fa fa-solid fa-road " aria-hidden="true"></span> Shorthand URLs</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="/about/download"><span class="fa fa-solid fa-download " aria-hidden="true"></span> Download</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="/about/rustdoc-json"><span class="fa fa-solid fa-file-code " aria-hidden="true"></span> Rustdoc JSON</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="/releases/queue"><span class="fa fa-solid fa-gears " aria-hidden="true"></span> Build queue</a></li><li class="pure-menu-item"><a class="pure-menu-link" href="https://foundation.rust-lang.org/policies/privacy-policy/#docs.rs" target="_blank"><span class="fa fa-solid fa-shield-halved " aria-hidden="true"></span> Privacy policy</a></li>
                        </ul>
                    </li>
                </ul>
                <ul class="pure-menu-list"><li class="pure-menu-item pure-menu-has-children">
                        <a href="#" class="pure-menu-link" aria-label="Rust">Rust</a>
                        <ul class="pure-menu-children">
                            <li class="pure-menu-item"><a class="pure-menu-link" href="https://www.rust-lang.org/" target="_blank">Rust website</a></li>
                            <li class="pure-menu-item"><a class="pure-menu-link" href="https://doc.rust-lang.org/book/" target="_blank">The Book</a></li>

                            <li class="pure-menu-item"><a class="pure-menu-link" href="https://doc.rust-lang.org/std/" target="_blank">Standard Library API Reference</a></li>

                            <li class="pure-menu-item"><a class="pure-menu-link" href="https://doc.rust-lang.org/rust-by-example/" target="_blank">Rust by Example</a></li>

                            <li class="pure-menu-item"><a class="pure-menu-link" href="https://doc.rust-lang.org/cargo/guide/" target="_blank">The Cargo Guide</a></li>

                            <li class="pure-menu-item"><a class="pure-menu-link" href="https://doc.rust-lang.org/nightly/clippy" target="_blank">Clippy Documentation</a></li>
                        </ul>
                    </li>
                </ul>
                
                <div id="search-input-nav">
                    <label for="nav-search">
                        <span class="fa fa-solid fa-magnifying-glass " aria-hidden="true"></span>
                    </label>

                    
                    
                    <input id="nav-search" name="query" type="text" aria-label="Find crate by search query" tabindex="-1"
                        placeholder="Find crate"
                        >
                </div>
            </form>
        </div>
    </div>
</div>


<div id="alerts" class="hidden"></div>
    
    <div class="docsrs-package-container">
        <div class="container">
            <div class="description-container">
                

                
                <h1 id="crate-title">
                    ai-jail 2.2.0
                    <span id="clipboard" class="svg-clipboard" title="Copy crate name and version information"></span>
                </h1>

                
                <div class="description">Sandbox for AI coding agents (bubblewrap on Linux, sandbox-exec on macOS)</div>


                <div class="pure-menu pure-menu-horizontal">
                    <ul class="pure-menu-list">
                        
                        <li class="pure-menu-item"><a href="/crate/ai-jail/2.2.0"
                                class="pure-menu-link">
                                <span class="fa fa-solid fa-cube " aria-hidden="true"></span>
                                <span class="title"> Crate</span>
                            </a>
                        </li>

                        
                        <li class="pure-menu-item">
                            <a href="/crate/ai-jail/2.2.0/source/README.md"
                                class="pure-menu-link pure-menu-active">
                                <span class="fa fa-regular fa-folder-open " aria-hidden="true"></span>
                                <span class="title"> Source</span>
                            </a>
                        </li>

                        
                        <li class="pure-menu-item">
                            <a href="/crate/ai-jail/2.2.0/builds"
                                class="pure-menu-link">
                                <span class="fa fa-solid fa-gears " aria-hidden="true"></span>
                                <span class="title"> Builds</span>
                            </a>
                        </li>

                        
                        <li class="pure-menu-item">
                            <a href="/crate/ai-jail/2.2.0/features"
                               class="pure-menu-link">
                                <span class="fa fa-solid fa-flag " aria-hidden="true"></span>
                                <span class="title">Feature flags</span>
                            </a>
                        </li>
                    </ul>
                </div>
            </div></div>
    </div>

    <div class="container package-page-container small-bottom-pad">
        <div class="pure-g">
            <div id="side-menu" class="pure-u-1 pure-u-sm-7-24 pure-u-md-5-24 source-view">
                <div class="pure-menu package-menu">
                    <ul class="pure-menu-list">
                        
                        
                            <li class="pure-menu-item toggle-source">
                                <button aria-label="Hide source sidebar" title="Hide source sidebar" aria-expanded="true"><span class="left"><span class="fa fa-solid fa-chevron-left " aria-hidden="true"></span></span><span class="right"><span class="fa fa-solid fa-chevron-right " aria-hidden="true"></span></span> <span class="text">Hide files</span></button>
                            </li>
                        
                        <li class="pure-menu-item">
                                
                                <a href="./releases/" class="pure-menu-link">
                                    <span class="fa fa-regular fa-folder-open " aria-hidden="true"></span>
                                    <span class="text">releases</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./src/" class="pure-menu-link">
                                    <span class="fa fa-regular fa-folder-open " aria-hidden="true"></span>
                                    <span class="text">src</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./tests/" class="pure-menu-link">
                                    <span class="fa fa-regular fa-folder-open " aria-hidden="true"></span>
                                    <span class="text">tests</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./.cargo_vcs_info.json" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file " aria-hidden="true"></span>
                                    <span class="text">.cargo_vcs_info.json</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./.envrc" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">.envrc</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./.gitignore" class="pure-menu-link">
                                    <span class="fa fa-brands fa-git-alt " aria-hidden="true"></span>
                                    <span class="text">.gitignore</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./Cargo.lock" class="pure-menu-link">
                                    <span class="fa fa-solid fa-lock " aria-hidden="true"></span>
                                    <span class="text">Cargo.lock</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./Cargo.toml" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">Cargo.toml</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./Cargo.toml.orig" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">Cargo.toml.orig</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./CLAUDE.md" class="pure-menu-link">
                                    <span class="fa fa-brands fa-markdown " aria-hidden="true"></span>
                                    <span class="text">CLAUDE.md</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./flake.lock" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">flake.lock</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./flake.nix" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">flake.nix</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./LICENSE" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">LICENSE</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./README.md" class="pure-menu-link">
                                    <span class="fa fa-brands fa-markdown " aria-hidden="true"></span>
                                    <span class="text">README.md</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./rust-toolchain.toml" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">rust-toolchain.toml</span>
                                </a>
                            </li><li class="pure-menu-item">
                                
                                <a href="./rustfmt.toml" class="pure-menu-link">
                                    <span class="fa fa-regular fa-file-lines " aria-hidden="true"></span>
                                    <span class="text">rustfmt.toml</span>
                                </a>
                            </li></ul>
                </div>
            </div>

            
                
                    
                
                <div id="source-code-container" class="pure-u-1 pure-u-sm-17-24 pure-u-md-19-24">
                    <div data-nosnippet class="source-code"><pre id="line-numbers"><code><a href="#1" id="1">1</a>
<a href="#2" id="2">2</a>
<a href="#3" id="3">3</a>
<a href="#4" id="4">4</a>
<a href="#5" id="5">5</a>
<a href="#6" id="6">6</a>
<a href="#7" id="7">7</a>
<a href="#8" id="8">8</a>
<a href="#9" id="9">9</a>
<a href="#10" id="10">10</a>
<a href="#11" id="11">11</a>
<a href="#12" id="12">12</a>
<a href="#13" id="13">13</a>
<a href="#14" id="14">14</a>
<a href="#15" id="15">15</a>
<a href="#16" id="16">16</a>
<a href="#17" id="17">17</a>
<a href="#18" id="18">18</a>
<a href="#19" id="19">19</a>
<a href="#20" id="20">20</a>
<a href="#21" id="21">21</a>
<a href="#22" id="22">22</a>
<a href="#23" id="23">23</a>
<a href="#24" id="24">24</a>
<a href="#25" id="25">25</a>
<a href="#26" id="26">26</a>
<a href="#27" id="27">27</a>
<a href="#28" id="28">28</a>
<a href="#29" id="29">29</a>
<a href="#30" id="30">30</a>
<a href="#31" id="31">31</a>
<a href="#32" id="32">32</a>
<a href="#33" id="33">33</a>
<a href="#34" id="34">34</a>
<a href="#35" id="35">35</a>
<a href="#36" id="36">36</a>
<a href="#37" id="37">37</a>
<a href="#38" id="38">38</a>
<a href="#39" id="39">39</a>
<a href="#40" id="40">40</a>
<a href="#41" id="41">41</a>
<a href="#42" id="42">42</a>
<a href="#43" id="43">43</a>
<a href="#44" id="44">44</a>
<a href="#45" id="45">45</a>
<a href="#46" id="46">46</a>
<a href="#47" id="47">47</a>
<a href="#48" id="48">48</a>
<a href="#49" id="49">49</a>
<a href="#50" id="50">50</a>
<a href="#51" id="51">51</a>
<a href="#52" id="52">52</a>
<a href="#53" id="53">53</a>
<a href="#54" id="54">54</a>
<a href="#55" id="55">55</a>
<a href="#56" id="56">56</a>
<a href="#57" id="57">57</a>
<a href="#58" id="58">58</a>
<a href="#59" id="59">59</a>
<a href="#60" id="60">60</a>
<a href="#61" id="61">61</a>
<a href="#62" id="62">62</a>
<a href="#63" id="63">63</a>
<a href="#64" id="64">64</a>
<a href="#65" id="65">65</a>
<a href="#66" id="66">66</a>
<a href="#67" id="67">67</a>
<a href="#68" id="68">68</a>
<a href="#69" id="69">69</a>
<a href="#70" id="70">70</a>
<a href="#71" id="71">71</a>
<a href="#72" id="72">72</a>
<a href="#73" id="73">73</a>
<a href="#74" id="74">74</a>
<a href="#75" id="75">75</a>
<a href="#76" id="76">76</a>
<a href="#77" id="77">77</a>
<a href="#78" id="78">78</a>
<a href="#79" id="79">79</a>
<a href="#80" id="80">80</a>
<a href="#81" id="81">81</a>
<a href="#82" id="82">82</a>
<a href="#83" id="83">83</a>
<a href="#84" id="84">84</a>
<a href="#85" id="85">85</a>
<a href="#86" id="86">86</a>
<a href="#87" id="87">87</a>
<a href="#88" id="88">88</a>
<a href="#89" id="89">89</a>
<a href="#90" id="90">90</a>
<a href="#91" id="91">91</a>
<a href="#92" id="92">92</a>
<a href="#93" id="93">93</a>
<a href="#94" id="94">94</a>
<a href="#95" id="95">95</a>
<a href="#96" id="96">96</a>
<a href="#97" id="97">97</a>
<a href="#98" id="98">98</a>
<a href="#99" id="99">99</a>
<a href="#100" id="100">100</a>
<a href="#101" id="101">101</a>
<a href="#102" id="102">102</a>
<a href="#103" id="103">103</a>
<a href="#104" id="104">104</a>
<a href="#105" id="105">105</a>
<a href="#106" id="106">106</a>
<a href="#107" id="107">107</a>
<a href="#108" id="108">108</a>
<a href="#109" id="109">109</a>
<a href="#110" id="110">110</a>
<a href="#111" id="111">111</a>
<a href="#112" id="112">112</a>
<a href="#113" id="113">113</a>
<a href="#114" id="114">114</a>
<a href="#115" id="115">115</a>
<a href="#116" id="116">116</a>
<a href="#117" id="117">117</a>
<a href="#118" id="118">118</a>
<a href="#119" id="119">119</a>
<a href="#120" id="120">120</a>
<a href="#121" id="121">121</a>
<a href="#122" id="122">122</a>
<a href="#123" id="123">123</a>
<a href="#124" id="124">124</a>
<a href="#125" id="125">125</a>
<a href="#126" id="126">126</a>
<a href="#127" id="127">127</a>
<a href="#128" id="128">128</a>
<a href="#129" id="129">129</a>
<a href="#130" id="130">130</a>
<a href="#131" id="131">131</a>
<a href="#132" id="132">132</a>
<a href="#133" id="133">133</a>
<a href="#134" id="134">134</a>
<a href="#135" id="135">135</a>
<a href="#136" id="136">136</a>
<a href="#137" id="137">137</a>
<a href="#138" id="138">138</a>
<a href="#139" id="139">139</a>
<a href="#140" id="140">140</a>
<a href="#141" id="141">141</a>
<a href="#142" id="142">142</a>
<a href="#143" id="143">143</a>
<a href="#144" id="144">144</a>
<a href="#145" id="145">145</a>
<a href="#146" id="146">146</a>
<a href="#147" id="147">147</a>
<a href="#148" id="148">148</a>
<a href="#149" id="149">149</a>
<a href="#150" id="150">150</a>
<a href="#151" id="151">151</a>
<a href="#152" id="152">152</a>
<a href="#153" id="153">153</a>
<a href="#154" id="154">154</a>
<a href="#155" id="155">155</a>
<a href="#156" id="156">156</a>
<a href="#157" id="157">157</a>
<a href="#158" id="158">158</a>
<a href="#159" id="159">159</a>
<a href="#160" id="160">160</a>
<a href="#161" id="161">161</a>
<a href="#162" id="162">162</a>
<a href="#163" id="163">163</a>
<a href="#164" id="164">164</a>
<a href="#165" id="165">165</a>
<a href="#166" id="166">166</a>
<a href="#167" id="167">167</a>
<a href="#168" id="168">168</a>
<a href="#169" id="169">169</a>
<a href="#170" id="170">170</a>
<a href="#171" id="171">171</a>
<a href="#172" id="172">172</a>
<a href="#173" id="173">173</a>
<a href="#174" id="174">174</a>
<a href="#175" id="175">175</a>
<a href="#176" id="176">176</a>
<a href="#177" id="177">177</a>
<a href="#178" id="178">178</a>
<a href="#179" id="179">179</a>
<a href="#180" id="180">180</a>
<a href="#181" id="181">181</a>
<a href="#182" id="182">182</a>
<a href="#183" id="183">183</a>
<a href="#184" id="184">184</a>
<a href="#185" id="185">185</a>
<a href="#186" id="186">186</a>
<a href="#187" id="187">187</a>
<a href="#188" id="188">188</a>
<a href="#189" id="189">189</a>
<a href="#190" id="190">190</a>
<a href="#191" id="191">191</a>
<a href="#192" id="192">192</a>
<a href="#193" id="193">193</a>
<a href="#194" id="194">194</a>
<a href="#195" id="195">195</a>
<a href="#196" id="196">196</a>
<a href="#197" id="197">197</a>
<a href="#198" id="198">198</a>
<a href="#199" id="199">199</a>
<a href="#200" id="200">200</a>
<a href="#201" id="201">201</a>
<a href="#202" id="202">202</a>
<a href="#203" id="203">203</a>
<a href="#204" id="204">204</a>
<a href="#205" id="205">205</a>
<a href="#206" id="206">206</a>
<a href="#207" id="207">207</a>
<a href="#208" id="208">208</a>
<a href="#209" id="209">209</a>
<a href="#210" id="210">210</a>
<a href="#211" id="211">211</a>
<a href="#212" id="212">212</a>
<a href="#213" id="213">213</a>
<a href="#214" id="214">214</a>
<a href="#215" id="215">215</a>
<a href="#216" id="216">216</a>
<a href="#217" id="217">217</a>
<a href="#218" id="218">218</a>
<a href="#219" id="219">219</a>
<a href="#220" id="220">220</a>
<a href="#221" id="221">221</a>
<a href="#222" id="222">222</a>
<a href="#223" id="223">223</a>
<a href="#224" id="224">224</a>
<a href="#225" id="225">225</a>
<a href="#226" id="226">226</a>
<a href="#227" id="227">227</a>
<a href="#228" id="228">228</a>
<a href="#229" id="229">229</a>
<a href="#230" id="230">230</a>
<a href="#231" id="231">231</a>
<a href="#232" id="232">232</a>
<a href="#233" id="233">233</a>
<a href="#234" id="234">234</a>
<a href="#235" id="235">235</a>
<a href="#236" id="236">236</a>
<a href="#237" id="237">237</a>
<a href="#238" id="238">238</a>
<a href="#239" id="239">239</a>
<a href="#240" id="240">240</a>
<a href="#241" id="241">241</a>
<a href="#242" id="242">242</a>
<a href="#243" id="243">243</a>
<a href="#244" id="244">244</a>
<a href="#245" id="245">245</a>
<a href="#246" id="246">246</a>
<a href="#247" id="247">247</a>
<a href="#248" id="248">248</a>
<a href="#249" id="249">249</a>
<a href="#250" id="250">250</a>
<a href="#251" id="251">251</a>
<a href="#252" id="252">252</a>
<a href="#253" id="253">253</a>
<a href="#254" id="254">254</a>
<a href="#255" id="255">255</a>
<a href="#256" id="256">256</a>
<a href="#257" id="257">257</a>
<a href="#258" id="258">258</a>
<a href="#259" id="259">259</a>
<a href="#260" id="260">260</a>
<a href="#261" id="261">261</a>
<a href="#262" id="262">262</a>
<a href="#263" id="263">263</a>
<a href="#264" id="264">264</a>
<a href="#265" id="265">265</a>
<a href="#266" id="266">266</a>
<a href="#267" id="267">267</a>
<a href="#268" id="268">268</a>
<a href="#269" id="269">269</a>
<a href="#270" id="270">270</a>
<a href="#271" id="271">271</a>
<a href="#272" id="272">272</a>
<a href="#273" id="273">273</a>
<a href="#274" id="274">274</a>
<a href="#275" id="275">275</a>
<a href="#276" id="276">276</a>
<a href="#277" id="277">277</a>
<a href="#278" id="278">278</a>
<a href="#279" id="279">279</a>
<a href="#280" id="280">280</a>
<a href="#281" id="281">281</a>
<a href="#282" id="282">282</a>
<a href="#283" id="283">283</a>
<a href="#284" id="284">284</a>
<a href="#285" id="285">285</a>
<a href="#286" id="286">286</a>
<a href="#287" id="287">287</a>
<a href="#288" id="288">288</a>
<a href="#289" id="289">289</a>
<a href="#290" id="290">290</a>
<a href="#291" id="291">291</a>
<a href="#292" id="292">292</a>
<a href="#293" id="293">293</a>
<a href="#294" id="294">294</a>
<a href="#295" id="295">295</a>
<a href="#296" id="296">296</a>
<a href="#297" id="297">297</a>
<a href="#298" id="298">298</a>
<a href="#299" id="299">299</a>
<a href="#300" id="300">300</a>
<a href="#301" id="301">301</a>
<a href="#302" id="302">302</a>
<a href="#303" id="303">303</a>
<a href="#304" id="304">304</a>
<a href="#305" id="305">305</a>
<a href="#306" id="306">306</a>
<a href="#307" id="307">307</a>
<a href="#308" id="308">308</a>
<a href="#309" id="309">309</a>
<a href="#310" id="310">310</a>
<a href="#311" id="311">311</a>
<a href="#312" id="312">312</a>
<a href="#313" id="313">313</a>
<a href="#314" id="314">314</a>
<a href="#315" id="315">315</a>
<a href="#316" id="316">316</a>
<a href="#317" id="317">317</a>
<a href="#318" id="318">318</a>
<a href="#319" id="319">319</a>
<a href="#320" id="320">320</a>
<a href="#321" id="321">321</a>
<a href="#322" id="322">322</a>
<a href="#323" id="323">323</a>
<a href="#324" id="324">324</a>
<a href="#325" id="325">325</a>
<a href="#326" id="326">326</a>
<a href="#327" id="327">327</a>
<a href="#328" id="328">328</a>
<a href="#329" id="329">329</a>
<a href="#330" id="330">330</a>
<a href="#331" id="331">331</a>
<a href="#332" id="332">332</a>
<a href="#333" id="333">333</a>
<a href="#334" id="334">334</a>
<a href="#335" id="335">335</a>
<a href="#336" id="336">336</a>
<a href="#337" id="337">337</a>
<a href="#338" id="338">338</a>
<a href="#339" id="339">339</a>
<a href="#340" id="340">340</a>
<a href="#341" id="341">341</a>
<a href="#342" id="342">342</a>
<a href="#343" id="343">343</a>
<a href="#344" id="344">344</a>
<a href="#345" id="345">345</a>
<a href="#346" id="346">346</a>
<a href="#347" id="347">347</a>
<a href="#348" id="348">348</a>
<a href="#349" id="349">349</a>
<a href="#350" id="350">350</a>
<a href="#351" id="351">351</a>
<a href="#352" id="352">352</a>
<a href="#353" id="353">353</a>
<a href="#354" id="354">354</a>
<a href="#355" id="355">355</a>
<a href="#356" id="356">356</a>
<a href="#357" id="357">357</a>
<a href="#358" id="358">358</a>
<a href="#359" id="359">359</a>
<a href="#360" id="360">360</a>
<a href="#361" id="361">361</a>
<a href="#362" id="362">362</a>
<a href="#363" id="363">363</a>
<a href="#364" id="364">364</a>
<a href="#365" id="365">365</a>
<a href="#366" id="366">366</a>
<a href="#367" id="367">367</a>
<a href="#368" id="368">368</a>
<a href="#369" id="369">369</a>
<a href="#370" id="370">370</a>
<a href="#371" id="371">371</a>
<a href="#372" id="372">372</a>
<a href="#373" id="373">373</a>
<a href="#374" id="374">374</a>
<a href="#375" id="375">375</a>
<a href="#376" id="376">376</a>
<a href="#377" id="377">377</a>
<a href="#378" id="378">378</a>
<a href="#379" id="379">379</a>
<a href="#380" id="380">380</a>
<a href="#381" id="381">381</a>
<a href="#382" id="382">382</a>
<a href="#383" id="383">383</a>
<a href="#384" id="384">384</a>
<a href="#385" id="385">385</a>
<a href="#386" id="386">386</a>
<a href="#387" id="387">387</a>
<a href="#388" id="388">388</a>
<a href="#389" id="389">389</a>
<a href="#390" id="390">390</a>
<a href="#391" id="391">391</a>
<a href="#392" id="392">392</a>
<a href="#393" id="393">393</a>
<a href="#394" id="394">394</a>
<a href="#395" id="395">395</a>
<a href="#396" id="396">396</a>
<a href="#397" id="397">397</a>
<a href="#398" id="398">398</a>
<a href="#399" id="399">399</a>
<a href="#400" id="400">400</a>
<a href="#401" id="401">401</a>
<a href="#402" id="402">402</a>
<a href="#403" id="403">403</a>
<a href="#404" id="404">404</a>
<a href="#405" id="405">405</a>
<a href="#406" id="406">406</a>
<a href="#407" id="407">407</a>
<a href="#408" id="408">408</a>
<a href="#409" id="409">409</a>
<a href="#410" id="410">410</a>
<a href="#411" id="411">411</a>
<a href="#412" id="412">412</a>
<a href="#413" id="413">413</a>
<a href="#414" id="414">414</a>
<a href="#415" id="415">415</a>
<a href="#416" id="416">416</a>
<a href="#417" id="417">417</a>
<a href="#418" id="418">418</a>
<a href="#419" id="419">419</a>
<a href="#420" id="420">420</a>
<a href="#421" id="421">421</a>
<a href="#422" id="422">422</a>
<a href="#423" id="423">423</a>
<a href="#424" id="424">424</a>
<a href="#425" id="425">425</a>
<a href="#426" id="426">426</a>
<a href="#427" id="427">427</a>
<a href="#428" id="428">428</a>
<a href="#429" id="429">429</a>
<a href="#430" id="430">430</a>
</code></pre></div>
                    <div id="source-code" class="source-code"><pre><code><span class="syntax-text syntax-html syntax-markdown"><span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">ai-jail</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
**[aijail.io](https://aijail.io)**

`ai-jail` runs AI coding agents in an OS sandbox: bubblewrap plus Landlock,
seccomp, and limits on Linux; `sandbox-exec` on macOS. It is a useful layer,
not a replacement for a disposable VM when running hostile code.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Install</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
```bash
<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Homebrew</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>brew tap akitaonrails/tap &amp;&amp; brew install ai-jail

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Arch Linux</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>yay -S ai-jail-bin       # prebuilt Linux x86_64 binary
yay -S ai-jail           # build from source

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">crates.io</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>cargo install --locked ai-jail

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Nix (flake) — sets BWRAP_BIN automatically</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>nix run github:akitaonrails/ai-jail -- claude
nix profile install github:akitaonrails/ai-jail

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">GitHub Releases (signed archives, checksums alongside)</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span><span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">ai-jail-linux-x86_64.tar.gz / ai-jail-macos-aarch64.tar.gz</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>```

Build from source with Rust `1.97.1`:

```bash
cargo build --release --locked
install -Dm755 target/release/ai-jail ~/.local/bin/ai-jail
```

Linux requires `bwrap` (`bubblewrap`): `pacman -S bubblewrap`,
`apt install bubblewrap`, or `dnf install bubblewrap`. `BWRAP_BIN` is accepted
only when it canonically resolves to a root-owned executable that is not
group- or world-writable, or to an executable with no write bits under a
`/nix/store` whose own owner is root (or an unmapped owner inside a user
namespace), is not world-writable, and carries the sticky bit if it is
group-writable — the standard multi-user store layout, mode `1775`. A
group-writable store without the sticky bit is refused, because a group member
could then replace the binary. A single-user store owned by the invoking user
does not qualify either.
macOS uses Apple&#39;s deprecated `/usr/bin/sandbox-exec` interface. Windows is not
supported; use WSL2 and the Linux backend inside it.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Quick start</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
```bash
cd ~/Projects/my-app
ai-jail claude                 # no agent credentials mounted
ai-jail --agent-state claude   # mount Claude&#39;s credential state
ai-jail --dry-run claude
```

The project directory is writable by default; host capabilities are not. The
first ordinary run may create `.ai-jail`; `--dry-run` never writes it. Existing
unreadable or invalid project/global configuration fails closed rather than
launching with a weakened policy. Bootstrap output is always mode `0600`.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Secure defaults</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
Private home is **on** by default: the agent gets a fresh tmpfs `$HOME`, not
your host home. Agent credential state (Claude&#39;s `~/.claude` and
`~/.claude.json`, for example) is **not** mounted unless you ask for it:

```bash
ai-jail --agent-state claude
```

or in trusted global config:

```toml
<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown"><span class="syntax-markup syntax-strikethrough syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-strikethrough syntax-begin syntax-markdown">~</span>/.ai-jail
[commands.claude]
agent_state = true
<span class="syntax-meta syntax-code-fence syntax-definition syntax-begin syntax-text syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-raw syntax-code-fence syntax-begin syntax-markdown">```</span>
</span><span class="syntax-markup syntax-raw syntax-code-fence syntax-markdown-gfm">
Mounting agent state exposes that agent&#39;s login/session material to everything
running in the sandbox, so it stays opt-in. Use `--no-private-home` only when
deliberately granting broad host-home access; `--map` and `--rw-map` remain
explicit, narrow alternatives.

The following capabilities default **off**: network, GPU, display, linked Git
worktree metadata, X11, host shared memory, terminal passthrough, update
check, and macOS host IPC. Docker, SSH, Pictures, Tailscale, and the systemd
user bus are also off by default.

| Flag pair                                              | Effect and security consequence                                                                                                                                                                  |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `--network` / `--no-network`                           | Enables/disables unrestricted network. `--network` permits full network exfiltration of any readable data.                                                                                       |
| `--gpu` / `--no-gpu`                                   | Enables/disables GPU device access.                                                                                                                                                              |
| `--display` / `--no-display`                           | Enables/disables display access. Only the validated Wayland socket is mounted; ai-jail never mounts all of `XDG_RUNTIME_DIR`. X11 is separate (`--x11`).                                         |
| `--x11` / `--no-x11`                                   | Enables/disables X11 separately. X11 access permits keylogging and screenshots.                                                                                                                  |
| `--audio` / `--no-audio`                               | Enables/disables host audio (Linux only). Binds the validated PipeWire/PulseAudio sockets in `XDG_RUNTIME_DIR` plus `/dev/snd`; anything in the sandbox can record and play audio while enabled. |
| `--host-shm` / `--no-host-shm`                         | Enables/disables host `/dev/shm`; enabling it opens host cross-process IPC.                                                                                                                      |
| `--terminal-passthrough` / `--no-terminal-passthrough` | Enables/disables raw terminal forwarding. Output is filtered through a VT parser by default; raw forwarding exposes terminal clipboard, query, and parser surface.                               |
| `--agent-state` / `--no-agent-state`                   | Enables/disables mounting the invoked command&#39;s credential state (default off). Enables the agent to authenticate — and lets anything in the sandbox use those credentials.                      |
| `--inherit-env` / `--no-inherit-env`                   | Default is a minimal environment allowlist. `--inherit-env` passes the full parent environment, secrets included.                                                                                |
| `--update-check` / `--no-update-check`                 | Enables the status bar&#39;s outbound GitHub version check, run in a background thread while the interactive status bar is active (default off; all other launches make no network requests).        |
| `--macos-host-ipc` / `--no-macos-host-ipc`             | Enables/disables macOS Mach, IOKit, and host IPC exposure.                                                                                                                                       |
| `--worktree` / `--no-worktree`                         | Enables/disables validated linked-worktree metadata. When enabled, the per-worktree git dir and the shared common dir are writable so the agent can commit; `--lockdown` keeps both read-only.   |
| `--private-home` / `--no-private-home`                 | Enables/disables the default private home. Disabling it is broad host-home access.                                                                                                               |

`--allow-host HOST` (repeatable, or `allow_hosts = [...]` in `.ai-jail`)
enables filtered egress instead: the sandbox keeps no route off the host
except a built-in CONNECT proxy that dials exactly the listed hosts — an
entry matches the host itself and its subdomains. On Linux the fence is a
private network namespace whose only reachable endpoint is an in-sandbox
bridge; on macOS it is a seatbelt endpoint rule allowing outbound only to
the proxy&#39;s loopback port. It is TCP/CONNECT-only:
no UDP, and no working DNS inside the sandbox on Linux (on macOS the system
resolver is not fenced). It cannot combine with `--network` or `--browser`,
and a project `.ai-jail` may only shrink the list, never grow it.

### Phantom credentials: `--secret KEY=host`

With filtered egress on, `--secret ANTHROPIC_API_KEY=api.anthropic.com`
(repeatable, or `secret_hosts = { ... }` in the global config) keeps the real
value out of the sandbox: the child env carries an `AIJAIL-PHANTOM-…`
placeholder, and the egress proxy swaps in the real value only for requests
terminating at the bound host. The key must already be passed via `--env` or
`--env-from-file`. One honest caveat: CONNECT tunnels stay opaque — this only
covers clients that can speak plain HTTP to the proxy (e.g. an
`ANTHROPIC_BASE_URL=http://…` override); those requests are terminated and
re-originated over TLS by the supervisor, which therefore sees that plaintext
for secret-bound hosts. HTTPS clients that only CONNECT keep working exactly
as before, with no substitution.

`--allow-tcp-port` remains accepted for backward compatibility, but launch
fails closed because UDP cannot be securely constrained through this option —
use `--allow-host` for filtered egress instead.
Use `--network` only when unrestricted network access is explicitly desired.

`--docker` mounts an actual Unix Docker socket and is effectively host-root:
the daemon can create host-mounted containers. `DOCKER_HOST` must identify an
actual Unix socket; TCP/SSH endpoints are not mounted. `~/.docker` is not
broadly mounted. `--systemd-user` exposes only explicit user-bus sockets, but
can still ask the host user manager to run services.

## Environment policy

By default the sandbox receives only a minimal allowlist of terminal, locale,
and toolchain variables — not your shell environment. Extend it explicitly:

```bash
ai-jail --env CI --env API_BASE=https://internal.example claude
</span><span class="syntax-meta syntax-code-fence syntax-definition syntax-end syntax-text syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-raw syntax-code-fence syntax-end syntax-markdown">```</span>
</span><span class="syntax-invalid syntax-illegal syntax-non-terminated syntax-bold-italic syntax-markdown">
</span></span></span></span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-bullet syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">-</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"> <span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"><span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--env NAME<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> forwards one variable from the parent environment.
</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-bullet syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">-</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"> <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--env NAME=VALUE<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> sets a literal value.
</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-bullet syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">-</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"> Both forms are repeatable; a later <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--env<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> for the same name wins.
</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-bullet syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">-</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"> <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--inherit-env<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> passes the entire parent environment instead. This exports
</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">  </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">every secret currently in your shell into the sandbox; avoid it.
</span>
</span>The same thing is available from trusted config as `env_pass`, so you do not
have to repeat `--env` on every launch:

```toml
<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown"><span class="syntax-markup syntax-strikethrough syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-strikethrough syntax-begin syntax-markdown">~</span>/.ai-jail
env_pass = [&quot;CI&quot;, &quot;API_BASE=<span class="syntax-markup syntax-underline syntax-link syntax-markdown-gfm">https://internal.example</span><span class="syntax-markup syntax-underline syntax-link syntax-markdown-gfm">&quot;]</span>
<span class="syntax-invalid syntax-illegal syntax-non-terminated syntax-bold-italic syntax-markdown">
</span></span></span></span></span>[commands.claude]
env_pass = [&quot;ANTHROPIC_BASE_URL&quot;]
```

`env_pass` is a trusted-layer field: it is read from the global config and its
`[commands.&lt;name&gt;]` tables, and ignored in a project `.ai-jail`, since a
repository must not be able to pull variables out of your shell. It is also
never written back to disk, because `NAME=VALUE` entries can carry secrets.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">###</span> </span><span class="syntax-markup syntax-heading syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Credential hygiene: <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--env-from-file<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span></span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
For API keys and similar secrets, keep them out of every `.ai-jail` file:
pass them from the host environment via `--env NAME`, or from a 0600 file
via `--env-from-file PATH` (repeatable; also `env_from_file` in the global
config). Each file must be user-owned, a regular file (never a symlink),
mode 0600 or stricter, and live outside the project directory — any
violation fails the launch. The format is strict `KEY=VALUE` lines (`#`
comments and blank lines are skipped; no `export` prefix, no quote
stripping). Entries apply like `--env`, and `--env` wins on conflicts.
Auto-save strips them, but don&#39;t rely on it: write secrets into files or
your shell, never into config.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Project secrets</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
The project directory is writable by default, so secrets inside it are
readable by the agent unless you mask or deny them:

```toml
<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">.ai-jail (project config — untrusted, but tightening like this is honored)</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>mask = [&quot;.env&quot;, &quot;.env.*&quot;, &quot;*.pem&quot;]
deny_paths = [&quot;secrets/&quot;]
```

<span class="syntax-markup syntax-list syntax-unnumbered syntax-bullet syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">-</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"> <span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"><span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--mask PATH|GLOB<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> replaces matching project paths with empty placeholders:
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">  </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">the agent sees the path exists but gets no content.
</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-bullet syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">-</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"> <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--deny-path PATH|GLOB<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> makes matching paths inaccessible entirely.
</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-bullet syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">-</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"> <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--mask-except<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> / <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>--deny-path-except<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> carve out exceptions.
</span></span><span class="syntax-markup syntax-list syntax-unnumbered syntax-markdown">
</span>Masks and denies apply to paths that **exist when the sandbox is built**.
A literal path that is missing at launch, or a glob that matches nothing, is
skipped with a warning — and a file created later, inside the session, is not
covered. Create the file before launching (an empty `.env` is enough) when you
need the rule enforced. Quote glob patterns so ai-jail receives the pattern
instead of your shell expanding it first.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Ephemeral home and temp</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
The private home is a fresh tmpfs per launch. Nothing persists between runs
except state you explicitly mount (agent state, `--rw-map`, command tables).
On Linux `/tmp` inside the sandbox is sandbox-local and discarded on exit;
writes to dotfiles and caches vanish with the sandbox. macOS has no mount
namespace, so `/tmp` is the host&#39;s: `TMPDIR` instead points at a private
per-launch session directory (mode `0700`), and that is the only temp path
the profile grants. The one exception is `ai-jail claude` on macOS, which is
also granted write access to `/private/tmp/claude-&lt;your uid&gt;` because Claude
Code creates that directory unconditionally at startup and ignores `TMPDIR`;
unlike the session directory, it persists between runs. Use a map or
`--agent-state` for anything durable.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Browsers</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
`--browser[=hard|soft]` reuses an isolated browser profile, but browsers still
need `--network` and `--display` passed explicitly on Linux (on macOS the
display is system-level, so only `--network` applies there); `--browser` alone
produces a browser that cannot load pages — and on Linux cannot open a window.
X11-based browsers need `--x11` instead of `--display`. Audio (e.g. video
playback) additionally needs `--audio`, which binds the validated
PipeWire/PulseAudio sockets — `ai-jail --browser=soft --network --display
--audio chromium`.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Configuration</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
Two config files plus CLI flags, in increasing authority:

<span class="syntax-markup syntax-list syntax-numbered syntax-bullet syntax-markdown">1<span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">.</span></span><span class="syntax-markup syntax-list syntax-numbered syntax-markdown"> <span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"><span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>./.ai-jail<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> (project) — untrusted, monotonic policy: it may tighten the
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">sandbox but can never enable capabilities, outside maps, ports,
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"><span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>claude_dir<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span>, or exceptions. It is masked from the sandbox by default, so
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">the agent sees an empty file rather than your policy. Add <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>.ai-jail<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> to
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"><span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>.gitignore<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> and leave it uncommitted if you would rather the agent not
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">notice it at all: <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>git status<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> inside the sandbox is then completely
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">clean. A <span class="syntax-markup syntax-italic syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-italic syntax-begin syntax-markdown">_</span>committed<span class="syntax-punctuation syntax-definition syntax-italic syntax-end syntax-markdown">_</span></span> <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>.ai-jail<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> always shows as modified there, because
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">masking replaces its contents — git has to report something either way.
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">To let specific checkouts ship their own capability opt-ins, list their
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">parent directory under <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>trust_project_config<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> in the global config (see
</span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">below).
</span></span><span class="syntax-markup syntax-list syntax-numbered syntax-bullet syntax-markdown">2<span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">.</span></span><span class="syntax-markup syntax-list syntax-numbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"> <span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>~/.ai-jail<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> (global, trusted) — a base table plus optional
</span></span><span class="syntax-markup syntax-list syntax-numbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown">   </span><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"><span class="syntax-markup syntax-raw syntax-inline syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-raw syntax-begin syntax-markdown">`</span>[commands.&lt;name&gt;]<span class="syntax-punctuation syntax-definition syntax-raw syntax-end syntax-markdown">`</span></span> tables keyed by the first word of the command.
</span></span><span class="syntax-markup syntax-list syntax-numbered syntax-bullet syntax-markdown">3<span class="syntax-punctuation syntax-definition syntax-list_item syntax-markdown">.</span></span><span class="syntax-markup syntax-list syntax-numbered syntax-markdown"><span class="syntax-meta syntax-paragraph syntax-list syntax-markdown"> CLI flags — highest authority.
</span></span><span class="syntax-markup syntax-list syntax-numbered syntax-markdown">
</span>A `[commands.&lt;name&gt;]` table merges over the global base: scalar fields it sets
override the base (status-bar fields stay from the base), list fields (maps,
masks) append.

Common fields: `command`, `rw_maps`, `ro_maps`, `overlay_maps`, `mask`,
`deny_paths`, `mask_exceptions`, `deny_path_exceptions`, `hide_dotdirs`,
`network`, `x11`, `host_shm`, `terminal_passthrough`, `macos_host_ipc`,
`systemd_user`, `ssh`, `pictures`, `private_home`, `lockdown`,
`browser_profile`, `claude_dir`, `allow_tcp_ports`, `status_bar_style`.

Global config only: `env_pass` (see Environment policy above) and
`trust_project_config`, which lists directories whose project
`.ai-jail` may enable capabilities rather than only tighten, for teams that
ship per-repository policy:

```toml
<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown"><span class="syntax-markup syntax-strikethrough syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-strikethrough syntax-begin syntax-markdown">~</span>/.ai-jail
trust_project_config = [&quot;<span class="syntax-punctuation syntax-definition syntax-strikethrough syntax-end syntax-markdown">~</span></span>/work/repos&quot;]</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>```

Everything at or beneath a listed directory is trusted, including repositories
cloned there later, so keep the list narrow. A project file that sets this
itself is ignored.

Legacy polarity warning: older boolean fields keep their inverted `no_*`
names (`no_gpu`, `no_docker`, `no_display`, `no_worktree`, `no_mise`,
`no_landlock`, `no_seccomp`, `no_rlimits`, `no_save_config`, `no_hide_config`,
`no_status_bar`), where `true` disables the capability. Newer fields use
positive names (`network`, `x11`, `ssh`, `agent_state`, ...) where `true`
enables it. Unknown fields are ignored, and missing fields keep their
defaults, so old config files keep parsing across upgrades.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Useful options</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
```text
ai-jail [OPTIONS] [--] [COMMAND [ARGS...]]

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-meta syntax-table syntax-header syntax-markdown-gfm">--map PATH<span class="syntax-punctuation syntax-separator syntax-table-cell syntax-markdown">|</span>SOURCE:DEST          read-only extra mount (repeatable)
</span><span class="syntax-meta syntax-table syntax-header-separator syntax-markdown-gfm"><span class="syntax-punctuation syntax-section syntax-table-header syntax-markdown">--</span>rw<span class="syntax-punctuation syntax-section syntax-table-header syntax-markdown">-</span>map PATH<span class="syntax-punctuation syntax-separator syntax-table-cell syntax-markdown">|</span>SOURCE<span class="syntax-punctuation syntax-definition syntax-table-cell-alignment syntax-markdown">:</span>DEST       read<span class="syntax-punctuation syntax-section syntax-table-header syntax-markdown">-</span>write extra mount (repeatable)
</span><span class="syntax-meta syntax-table syntax-markdown-gfm">--overlay-map PATH              copy-on-write mount (Linux only; read-only map on macOS)
--mask PATH<span class="syntax-punctuation syntax-separator syntax-table-cell syntax-markdown">|</span>GLOB                replace project paths with empty placeholders
--deny-path PATH<span class="syntax-punctuation syntax-separator syntax-table-cell syntax-markdown">|</span>GLOB           deny project paths
--agent-state / --no-agent-state  mount the command&#39;s credential state (default off)
--env NAME[=VALUE]              forward or set an environment variable (repeatable)
--inherit-env / --no-inherit-env  pass the full parent environment (default: allowlist)
--update-check / --no-update-check  host-side version check (default off)
--lockdown / --no-lockdown      strict read-only mode, no network by default
</span><span class="syntax-markup syntax-raw syntax-block syntax-markdown">                                (on Linux --network still overrides network
</span></span><span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-raw syntax-block syntax-markdown">                                isolation, subject to Landlock V4; macOS
</span></span><span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-raw syntax-block syntax-markdown">                                lockdown always blocks network)
</span></span>--docker / --no-docker          Docker socket (root-equivalent; off by default)
--systemd-user / --no-systemd-user  host user manager access (off by default)
--ssh / --no-ssh                read-only SSH/agent sharing (off by default)
--claude-dir PATH               explicit Claude state directory
--browser[=hard|soft]           isolated browser profile (needs --network --display)
--dry-run                       print the backend invocation
--init                          write configuration and exit
```

Linked worktrees are opt-in. When requested, ai-jail validates gitfile and
common-directory metadata and mounts the common metadata read-only. Kimi and
other agent state stays command-specific under private home.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">mise integration</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
If [mise](https://mise.jdx.dev/) is on `$PATH`, the sandbox runs
`mise trust -q`, `mise activate bash`, and `mise env` before your command, so
agents get the project&#39;s language versions. Disable with `--no-mise` or
`no_mise = true`. It is skipped automatically in `--lockdown` and browser
profile modes.

Activation is best-effort: if mise cannot run, or has neither its config nor
its installs inside the sandbox, it is skipped and your command still starts.

`PATH` is also pruned to the directories that actually exist inside the
sandbox, so entries describing the host&#39;s layout no longer make tools look
installed when nothing is mounted behind them.

**Under the default private home, mise has neither.** `$HOME` is a fresh
tmpfs, so `~/.config/mise` and `~/.local/share/mise` are not mounted, and the
inherited `PATH` still names the host&#39;s `~/.local/share/mise/installs/...`
directories even though nothing is there. Activation is therefore skipped
rather than left to fail slowly against the network. To give an agent a real
mise toolchain, map it in explicitly from trusted global config:

```toml
<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">#</span> </span><span class="syntax-markup syntax-heading syntax-1 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown"><span class="syntax-markup syntax-strikethrough syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-strikethrough syntax-begin syntax-markdown">~</span>/.ai-jail
[commands.claude]
ro_maps = [&quot;<span class="syntax-punctuation syntax-definition syntax-strikethrough syntax-end syntax-markdown">~</span></span>/.config/mise&quot;, &quot;<span class="syntax-markup syntax-strikethrough syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-strikethrough syntax-begin syntax-markdown">~</span>/.local/share/mise&quot;]
<span class="syntax-meta syntax-code-fence syntax-definition syntax-begin syntax-text syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-raw syntax-code-fence syntax-begin syntax-markdown">```</span>
</span><span class="syntax-markup syntax-raw syntax-code-fence syntax-markdown-gfm">
or use `--no-private-home` when you deliberately want the whole host home.

## Herdr

[Herdr](https://herdr.dev/) runs outside the sandbox, one `ai-jail` per pane,
the same as tmux. ai-jail needs no configuration for this, and the working
directory already lines up: the project is bound at its real path and the
sandbox `chdir`s there, so the pane&#39;s cwd matches inside and out.

Agent detection needs one variable. Herdr identifies the agent from the pane&#39;s
foreground process, and ai-jail&#39;s PTY proxy and PID namespace hide it, so name
the agent explicitly:

```bash
HERDR_AGENT=claude ai-jail claude
</span><span class="syntax-meta syntax-code-fence syntax-definition syntax-end syntax-text syntax-markdown-gfm"><span class="syntax-punctuation syntax-definition syntax-raw syntax-code-fence syntax-end syntax-markdown">```</span>
</span><span class="syntax-invalid syntax-illegal syntax-non-terminated syntax-bold-italic syntax-markdown">
</span></span></span></span></span>If Herdr still cannot resolve the process group through the sandbox, set
`HERDR_PROCESS_DETECTION=child-groups` in the Herdr environment.

If agent state is reported incorrectly, note that Herdr classifies state from
the pane&#39;s bottom screen rows, which is also where ai-jail&#39;s status bar draws;
`--no-status-bar` removes that overlap.

**Do not mount the Herdr control socket into the sandbox.** `HERDR_*` variables
and `~/.config/herdr/herdr.sock` are not passed in, and that is deliberate:
`herdr tab create` runs a command on the host, so an agent that can reach the
socket can execute outside the jail. Hook-based state reporting from inside the
sandbox would require exactly that, and it trades away the sandbox — leave
detection to `HERDR_AGENT` and screen manifests instead.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Troubleshooting</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
**`bwrap: setting up uid map: Permission denied` (Ubuntu 24.04+ / Debian 13+).**
These distros ship an AppArmor policy denying unprivileged user namespaces,
which is how `bwrap` isolates the sandbox. This affects every rootless
user-namespace tool (Distrobox, rootless Podman, Flatpak from non-standard
paths), not just ai-jail. Relax it system-wide:

```bash
echo &#39;kernel.apparmor_restrict_unprivileged_userns=0&#39; \
  | sudo tee /etc/sysctl.d/60-userns.conf
sudo sysctl --system
```

Or keep the rest of the policy intact with an unconfined profile for `bwrap`
only, in `/etc/apparmor.d/bwrap`:

```
abi &lt;abi/4.0&gt;,
include &lt;tunables/global&gt;
profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,
}
```

Then `sudo apparmor_parser -r /etc/apparmor.d/bwrap`.

**`Failed to create stream fd: No such file or directory` at startup.**
This comes from mise setup, not from ai-jail. mise activation runs under a
login shell, which sources `/etc/profile.d/*.sh`; on Ubuntu desktop one of
those scripts (for example `im-config_wayland.sh`) logs through `systemd-cat`,
and the journald socket does not exist inside the sandbox. It is harmless and
mise still initializes. Silence it by masking the offending script
(`mask = [&quot;/etc/profile.d/im-config_wayland.sh&quot;]`) or by skipping mise setup
entirely with `--no-mise`.

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">Platform and threat model</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
Linux uses namespace isolation and, where available, Landlock, seccomp, and
resource limits. macOS has no global filesystem reads, network, or host IPC by
default; `--agent-state` and other state mounts work on both platforms.
Overlay maps are copy-on-write on Linux only; on macOS they are honored as
read-only maps. `sandbox-exec` is deprecated and neither backend protects
against kernel/driver vulnerabilities, terminal emulator vulnerabilities, or
all IPC and side-channel classes. For truly hostile workloads, use a
disposable VM.

See [docs/SECURITY.md](docs/SECURITY.md) for the complete threat model,
capability matrix, residual risks, and disclosure guidance. Release
administrators should follow [docs/RELEASE_SECURITY.md](docs/RELEASE_SECURITY.md).

<span class="syntax-meta syntax-block-level syntax-markdown"><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-punctuation syntax-definition syntax-heading syntax-begin syntax-markdown">##</span> </span><span class="syntax-markup syntax-heading syntax-2 syntax-markdown"><span class="syntax-entity syntax-name syntax-section syntax-markdown">License</span><span class="syntax-meta syntax-whitespace syntax-newline syntax-markdown">
</span></span></span>
GPL-3.0-only. See [LICENSE](LICENSE).
</span></code></pre></div>
                </div></div>
    </div>
        <script nonce="ShiN1iOHtQEcxQF1FVreBB+c6TAAOxSY9NDpSUWtolIqE0b2" type="text/javascript" src="/-/static/source.js?0-0-0-6b0955898af88db642c5ce7420d9dbef2c65d5d9-2026-09-30"></script>
    </body>
</html>